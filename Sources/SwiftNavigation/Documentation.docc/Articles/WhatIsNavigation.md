# What is navigation?

Learn how one can think of navigation as a domain modeling problem, and how that leads to the
creation of concise and testable APIs for navigation.

## Overview

We will define navigation as a "mode" change in an application. The most prototypical example of
this is the drill-down. A user taps a button, and a right-to-left animation transitions you from the
current screen to the next screen.

> Important: Everything that follows is mostly focused on SwiftUI and UIKit navigation, but the 
ideas apply to other platforms too, such as Windows, Linux, WASM, and more.

But there are many more examples of navigation beyond stacks and links. Modals can be thought of as
navigation, too. A sheet can slide from bottom-to-top and transition you from the current screen to
a new screen. A full-screen cover can further take over the entire screen. Or a popover can
partially take over the screen.

Alerts and confirmation dialogs can also be thought of navigation as they are also modals that take
full control over the interface and force you to make a selection.

It's even possible for you to define your own notions of navigation, such as menus, notifications,
and more.

## State-driven navigation

All of these seemingly disparate examples of navigation can be unified under a single API.
Presentation and dismissal can be described with an optional piece of state:

  * When the state changes from `nil` to non-`nil`, a screen can be presented, whether that be
    _via_ a drill-down, modal, _etc._
  * And when the state changes from non-`nil` to `nil`, a screen can be dismissed.

Driving navigation from state like this can be incredibly powerful:

  * It guarantees that your model will always be in sync with the visual representation of the UI.
    It shouldn't be possible for a piece of state to be non-`nil` and not have the corresponding
    view present.
  * It easily enables deep linking capabilities. If all forms of navigation in your application are
    driven off of state, then you can instantly open your application into any state imaginable by
    simply constructing a piece of data, handing it to SwiftUI, and letting it do its thing.
  * It also allows you to write unit tests for navigation logic without resorting to UI tests, which
    can be slow, flakey, and introduce instability into your test suite. If you write a unit test
    showing that when a user performs an action that a piece of state went from `nil` to non-`nil`,
    then you can be assured that the user would be navigated to the next screen.

This is why state-driven navigation is so great. So, what are tools are at our disposal in Swift to
embrace this pattern?

## SwiftUI's tools for navigation

Many of SwiftUI's navigation tools are driven off of optional state.

The simplest example is modal sheets. A simple API is provided that takes a binding of an optional
item, and when that item flips to a non-`nil` value it is handed to a content closure to produce
a view, and that view is what is animated from bottom-to-top:

```swift
func sheet<Item: Identifiable, Content: View>(
  item: Binding<Item?>,
  onDismiss: (() -> Void)? = nil,
  content: @escaping (Item) -> Content
) -> some View
```

When SwiftUI detects the binding flips back to `nil`, the sheet will automatically be dismissed.

For example, suppose you have a list of items, and when one is tapped you want to bring up a modal
sheet for editing the item:

```swift
@Observable
class FeatureModel {
  var editingItem: Item?
  func tapped(item: Item) {
    editingItem = item
  }
  // ...
}

struct FeatureView: View {
  @ObservedObject var model: FeatureModel

  var body: some View {
    List {
      ForEach(model.items) { item in
        Button(item.name) {
          model.tapped(item: item)
        }
      }
    }
    .sheet(item: $model.editingItem) { item in
      EditItemView(item: item)
    }
  }
}
```

This works really great. When the button is tapped, the `tapped(item:)` method is called on the
model causing the `editingItem` state to be hydrated, and then SwiftUI sees that value is no longer
`nil` and so it causes the sheet to be presented.

A lot of SwiftUI's navigation APIs follow this pattern. For example, here's the signatures for
showing popovers and full screen covers:

```swift
func popover<Item: Identifiable, Content: View>(
  item: Binding<Item?>,
  attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
  arrowEdge: Edge = .top,
  @ViewBuilder content: @escaping (Item) -> Content
) -> some View

func fullScreenCover<Item: Identifiable, Content: View>(
  item: Binding<Item?>,
  onDismiss: (() -> Void)? = nil,
  @ViewBuilder content: @escaping (Item) -> Content
) -> some View
```

There is even a drill-down API of this form:

```swift
public func navigationDestination<D: Hashable, C: View>(
  item: Binding<D?>,
  @ViewBuilder destination: @escaping (D) -> C
) -> some View
```

All of these APIs take a binding of an optional and a content closure for transforming the non-`nil`
state into a view that is presented in the popover or cover.

There are, however, a few problems with these APIs.

First, many of them require an `Identifiable` conformance for the underlying data. The identity of
the data lets SwiftUI dismiss and represent a modal when it detects a change, which is a great
feature to have, but often the data you want to present does not conform to `Identifiable`, and
introducing a conformance comes with a lot of questions and potential boilerplate.

SwiftUI already provides an elegant solution to the problem in its `ForEach` view, which takes an
`id` parameter to single out an element's identity without requiring an `Identifiable` conformance.
So, what if `sheet`, `fullScreenCover` and `popover` were given the same treatment?

```swift
.sheet(item: $model.title, id: \.self) { title in
  Text(title)
}
```

Unfortunately SwiftUI comes with no such API.

The second problem is that the argument passed to the `content` closure is the plain, unwrapped
value. This means the modal content is handed a potentially inert value. If that modal view wants to
make mutations to this value it will need to find a way to communicate that back to the parent.

However, two-way communication is already a solved problem in SwiftUI with bindings. So, it might be
better if the `sheet(item:content:)` API handed a binding to the unwrapped item so that any
mutations in the sheet would be instantly observable by the parent:

```swift
.sheet(item: $model.editingItem) { $item in
  EditItemView(item: $item)
}
```

However, this is not the API exposed to us from SwiftUI.

The third problem is that while optional state is a great way to drive navigation, not all SwiftUI
APIs are as concise as the above examples. For example, alerts and dialogs are not only driven by
optional state, but also a boolean:

```swift
.alert(
  Text("Confirm deletion"),
  isPresented: $model.isAlertPresented,
  presenting: item
) { item in
  Button("Nevermind", role: .cancel)
  Button("Delete \(item.name)", role: .destructive)
}
```

Modeling the domain in this way unfortunately introduces a couple invalid runtime states:

  * `isPresented` can be `true`, but `item` can be `nil`.
  * `isPresented` can be `false`, but `item` can be non-`nil`.

On top of that, SwiftUI's `alert` modifiers take static titles, which means the title cannot be
dynamically computed from the alert data.

What if SwiftUI has alert and dialog modifiers that looked a little more like its other navigation
modifiers, with the added feature of giving the alert title access to the underlying data?

```swift
.alert(item: $item) { item in
  Text("Delete \(item.name)"?)
} actions: { _ in
  Button("Nevermind", role: .cancel)
  Button("Delete", role: .destructive)
}
```

The third problem is that while optional state is a great way to drive navigation, it doesn't scale
to multiple navigation destinations.

For example, suppose that in addition to being able to edit an item, the feature can also add an
item and duplicate an item, and you can navigate to a help screen. That can technically be
represented as four optionals:

```swift
@Observable
class FeatureModel {
  var addItem: Item?
  var duplicateItem: Item?
  var editingItem: Item?
  var help: Help?
  // ...
}
```

But this is not the most concise way to model this domain. Four optional values means there are
2⁴&nbsp;=&nbsp;16 different states this feature can be in, but only 5 of those states are valid:
either all can be `nil`, representing we are not navigated anywhere, or at most one can be
non-`nil`, representing navigation to a single screen.

But it is not valid to have 2, 3 or 4 non-`nil` values. That would represent multiple screens
being simultaneously navigated to, such as two sheets being presented, which is invalid in SwiftUI
and can even cause crashes. And 11 of those 16 states—the vast majority—are invalid.

This is showing that 4 optionals is not the best way to represent 4 navigation destinations.
Instead, it is more concise to model the 4 destinations as an enum with a case for each destination,
and then hold onto a single optional value to represent which destination is currently active:

```swift
@Observable
class FeatureModel {
  var destination: Destination?
  // ...

  enum Destination {
    case add(Item)
    case duplicate(Item)
    case edit(Item)
    case help(Help)
  }
}
```

This allows you to prove that at most one destination can be active at a time. It is impossible
to have both an "add" and "duplicate" screen presented at the same time.

But sadly SwiftUI does not come with the tools necessary to drive navigation off of an optional
enum. This is what motivated the creation of this library. It should be possible to represent all
of the screens a feature can navigate to as an enum, and then drive drill-downs, sheets, popovers,
covers, alerts, and more, from a particular case of that enum.

## SwiftUINavigation's tools

The tools that ship with this library aim to solve the problems discussed above and more. There are
new APIs for sheets, popovers, covers, alerts, confirmation dialogs, _and_ navigation stack
destinations that allow you to model destinations as an enum and drive navigation by a particular
case of the enum.

All of the APIs for these seemingly disparate forms of navigation are unified by a single pattern.
You first specify a binding to an optional value driving navigation, and then you specify some
content that takes a binding to a non-optional value.

For example, the new sheet API now takes a binding to an optional:

```swift
func sheet<Item: Hashable, Content: View>(
  item: Binding<Item?>,
  content: @escaping (Binding<Item>) -> Content
) -> some View
```

This single API allows you to not only drive the presentation and dismiss of a sheet from an
optional value, but also from a particular case of an enum.

In order to isolate a specific case of an enum we make use of our [CasePaths][case-paths-gh]
library. A case path is like a key path, except it is specifically tuned for abstracting over the
shape of enums rather than structs. A key path abstractly bundles up the functionality of getting
and setting a property on a struct, whereas a case path bundles up the functionality of "extracting"
a value from an enum and "embedding" a value into an enum. They are an indispensable tool for
transforming bindings.

Similar APIs are defined for popovers, covers, and more.

For example, consider a feature model that has 3 different destinations that can be navigated to:

```swift
@Observable
class FeatureModel {
  var destination: Destination?
  // ...

  @CasePathable
  enum Destination {
    case add(Item)
    case duplicate(Item)
    case edit(Item)
  }
}
```

We apply that `@CasePathable` macro to the enum in order to enable "dynamic case lookup" for SwiftUI
bindings, which will allow an optional binding to an enum chain into a particular case.

Suppose we want the `add` destination to be shown in a sheet, the `duplicate` destination to be
shown in a popover, and the `edit` destination in a drill-down. We can do so easily using the APIs
that ship with this library:

```swift
.popover(item: $model.destination.duplicate) { $item in
  DuplicateItemView(item: $item)
}
.sheet(item: $model.destination.add) { $item in
  AddItemView(item: $item)
}
.navigationDestination(item: $model.destination.edit) { $item in
  EditItemView(item: $item)
}
```

Even though all 3 forms of navigation are visually quite different, describing how to present them
is very consistent. You simply provide the binding to the optional enum held in the model, and then
you dot-chain into a particular case.

The above code uses the `navigationDestination` view modifier, which is only available in iOS 16 and
later. If you must support iOS 15 and earlier, you can use the following initializer on
`NavigationLink`, which also has a very similar API to the above:

```swift
NavigationLink(item: $model.destination.edit) { isActive in
  model.setEditIsActive(isActive)
} destination: { $item in
  EditItemView(item: $item)
} label: {
  Text("\(item.name)")
}
```

That is the basics of using this library's APIs for driving navigation off of state. Learn more by
reading the articles below.

## UIKit's tools for navigation

<!-- TODO -->

## UIKitNavigation's tools

<!-- TODO -->

## Topics

### Tools

Read the following articles to learn more about the tools that ship with this library for presenting
alerts, dialogs, sheets, popovers, covers, and navigation links all from bindings of enum state.

- <doc:Navigation>
- <doc:SheetsPopoversCovers>
- <doc:AlertsDialogs>
- <doc:Bindings>

[case-paths-gh]: http://github.com/pointfreeco/swift-case-paths
