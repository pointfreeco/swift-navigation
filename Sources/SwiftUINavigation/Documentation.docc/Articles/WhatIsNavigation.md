# What is navigation?

Learn how one can think of navigation as a domain modeling problem, and how that leads to the 
creation of concise and testable APIs for navigation.

## Overview

We will define navigation as a "mode" change in an application. The most prototypical example of 
this in SwiftUI are navigation stacks and links. A user taps a button, and a right-to-left 
animation transitions you from the current screen to the next screen.

But there are more examples of navigation beyond that one example. Modal sheets can be thought of
as navigation too. They slide from bottom-to-top and transition you from the current screen to a
new screen. Full screen covers and popovers are also an example of navigation, as they are very
similar to sheets except they either take over the full screen (i.e. covers) or only partially
take over the screen (i.e. popovers).

Even alerts and confirmation dialogs can be thought of navigation as they take full control over 
the interface and force you to make a selection. It's also possible for you to define your own 
notions of navigation, such as bottom sheets, toasts, and more.

## State-driven navigation

All of these seemingly disparate examples of navigation can be unified under a single API. The 
presentation and dismissal of a screen can be described with an optional piece of state. When the 
state changes from `nil` to non-`nil` the screen will be presented, whether that be via a 
drill-down, modal, popover, etc. And when the state changes from non-`nil` to `nil` the screen will
be dismissed.

Driving navigation from state like this can be incredibly powerful:

* It guarantees that your model will always be in sync with the visual representation of the UI. 
It shouldn't be possible for a piece of state to be non-`nil` and not have the corresponding view 
present.
* It easily enables deep linking capabilities. If all forms of navigation in your application are
driven off of state, then you can instantly open your application into any state imaginable by 
simply constructing a piece of state, handing it to SwiftUI, and letting it do its thing.
* It also allows you to write unit tests for navigation logic without resorting to UI tests, which
can be slow, flakey and introduce instability into your test suite. If you write a unit test that
shows when a user performs an action that a piece of state went from `nil` to non-`nil`, then you
can be assured that the user would be navigated to the next screen.

So, this is why state-driven navigation is so great. So, what tools does SwiftUI gives us to embrace
this pattern?

## SwiftUI's tools for navigation

Many of SwiftUI's navigation tools are driven off of optional state, but sadly not all.

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
    self.editingItem = item
  }
  // ...
}

struct FeatureView: View {
  @ObservedObject var model: FeatureModel

  var body: some View {
    List {
      ForEach(self.model.items) { item in 
        Button(item.name) {
          self.model.tapped(item: item)
        }
      }
    }
    .sheet(item: self.$model.editingItem) { item in 
      EditItemView(item: item)
    }
  }
}
```

This works really great. When the button is tapped, the `tapped(item:)` method is called on the 
model causing the `editingItem` state to be hydrated, and then SwiftUI sees that value is no longer
`nil` and so causes the sheet to be presented.

A lot of SwiftUI's navigation APIs follow this pattern. For example, here's the signatures for
showing popovers and full screen covers:

```swift
func popover<Item, Content>(
  item: Binding<Item?>,
  attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
  arrowEdge: Edge = .top,
  content: @escaping (Item) -> Content
) -> some View where Item : Identifiable, Content : View

func fullScreenCover<Item, Content>(
  item: Binding<Item?>,
  onDismiss: (() -> Void)? = nil,
  content: @escaping (Item) -> Content
) -> some View where Item : Identifiable, Content : View
```

Both take a binding of an optional and a content closure for transforming the non-`nil` state into
a view that is presented in the popover or cover.

There are, however, two potential problems with these APIs.

First, the argument passed to the `content` closure is the plain, non-`nil` value. This means the
sheet view presented is handed a plain, inert value, and if that view wants to make mutations it
will need to find a way to communicate that back to the parent. However, two-way communication
is already a solved problem in SwiftUI with bindings.

So, it might be better if the `sheet(item:content:)` API handed a binding to the unwrapped item so 
that any mutations in the sheet would be instantly observable by the parent:

```swift
.sheet(item: self.$model.editingItem) { $item in 
  EditItemView(item: $item)
}
```

However, this is not the API exposed to us from SwiftUI.

The second problem is that while optional state is a great way to drive navigation, it doesn't
scale to multiple navigation destinations.

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
`2⁴=16` different states this feature can be in, but only 5 of those states are valid. Either all
can be `nil`, representing we are not navigated anywhere, or at most one can be non-`nil`, 
representing navigation to a single screen.

But it is not valid to have 2, 3 or 4 non-`nil` values. That would represent multiple screens
being simultaneously navigated to, such as two sheets being presented, which is invalid in SwiftUI
and can even cause crashes.

This is showing that four optional values is not the best way to represent 4 navigation 
destinations. Instead, it is more concise to model the 4 destinations as an enum with a case for 
each destination, and then hold onto a single optional value to represent which destination
is currently active:

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
enum. This is what motivated the creation of this library. It should be possible to represent
all of the screens a feature can navigate to as an enum, and then drive sheets, popovers, covers
and more from a particular case of that enum.

## SwiftUINavigation's tools

The tools that ship with this library aim to solve the problems discussed above, and more. There are 
new APIs for sheets, popovers, covers, alerts, confirmation dialogs _and_ navigation  links that 
allow you to model destinations as an enum and drive navigation by a particular case of the enum.

All of the APIs for these seemingly disparate forms of navigation are unified by a single pattern.
You first specify a binding to the optional enum driving navigation, and then you specify the case
of the enum that you want to isolate.

For example, the new sheet API now takes a binding to an optional enum, and something known as a
[`CasePath`][case-paths-gh]:

```swift
func sheet<Enum, Case, Content>(
  unwrapping: Binding<Enum?>,
  case: CasePath<Enum, Case>,
  content: @escaping (Binding<Case>) -> Content
) -> some View where Content : View
```

This allows you to drive the presentation and dismiss of a sheet from a particular case of an enum.

In order to isolate a specific case of an enum we must make use of our [CasePaths][case-paths-gh]
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

  enum Destination {
    case add(Item)
    case duplicate(Item)
    case edit(Item)
  }
}
```

Suppose we want the `add` destination to be shown in a sheet, the `duplicate` destination to be
shown in a popover, and the `edit` destination in a drill-down. We can do so easily using the APIs
that ship with this library:

```swift
.popover(
  unwrapping: self.$model.destination,
  case: /FeatureModel.Destination.duplicate
) { $item in 
  DuplicateItemView(item: $item)
}
.sheet(
  unwrapping: self.$model.destination,
  case: /FeatureModel.Destination.add
) { $item in 
  AddItemView(item: $item)
}
.navigationDestination(
  unwrapping: self.$model.destination,
  case: /FeatureModel.Destination.edit
) { $item in 
  EditItemView(item: $item)
}
```

Even though all 3 forms of navigation are visually quite different, describing how to present them
is very consistent. You simply provide the binding to the optional enum held in the model, and then
you construct a case path for a particular case, which can be done by prefixing the case with a 
forward slash.

The above code uses the `navigationDestination` view modifier, which is only available in iOS 16.
If you must support iOS 15 and earlier, you can use the following initializer on `NavigationLink`,
which also has a very similar API to the above:

```swift
NavigationLink( 
  unwrapping: self.$model.destination,
  case: /FeatureModel.Destination.edit
) { isActive in 
  self.model.setEditIsActive(isActive)
} destination: { $item in 
  EditItemView(item: $item)
} label: {
  Text("\(item.name)")
}
```

That is the basics of using this library's APIs for driving navigation off of state. Learn more
by reading the articles below.

## Topics

### Tools

Read the following articles to learn more about the tools that ship with this library for presenting
alerts, dialogs, sheets, popovers, covers, and navigation links all from bindings of enum state. 

- <doc:Navigation>
- <doc:SheetsPopoversCovers>
- <doc:AlertsDialogs>
- <doc:DestructuringViews>
- <doc:Bindings>

[case-paths-gh]: http://github.com/pointfreeco/swift-case-paths
