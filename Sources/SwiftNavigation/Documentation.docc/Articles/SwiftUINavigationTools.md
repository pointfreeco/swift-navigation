# SwiftUI navigation

Learn more about SwiftUI's tools for navigations, and how this library improves upon them.

## SwiftUI's navigation tools

Many of SwiftUI's navigation tools are driven off of optional state. The simplest example is modal
sheets. A simple API is provided that takes a binding of an optional item, and when that item flips
to a non-`nil` value it is handed to a content closure to produce a view, and that view is what is
animated from bottom-to-top:

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

## The problems with SwiftUI's navigation tools

#### Identifiable requirement
  
First, many of them require an `Identifiable` conformance for the underlying data. The identity of
the data lets SwiftUI dismiss and represent a modal when it detects a change, which is a great
feature to have, but often the data you want to present does not conform to `Identifiable`, and
introducing a conformance comes with a lot of questions and potential boilerplate.

SwiftUI already provides an elegant solution to the problem in its `ForEach` view, which takes an
`id` parameter to single out an element's identity without requiring an `Identifiable` 
conformance. So, what if `sheet`, `fullScreenCover` and `popover` were given the same treatment?

```swift
.sheet(item: $model.title, id: \.self) { title in
  Text(title)
}
```

Unfortunately SwiftUI comes with no such API.

#### Passing bindings to child views
  
The second problem is that the argument passed to the `content` closure is the plain, unwrapped
value. This means the modal content is handed a potentially inert value. If that modal view wants 
to make mutations to this value it will need to find a way to communicate that back to the parent.

However, two-way communication is already a solved problem in SwiftUI with bindings. So, it might 
be better if the `sheet(item:content:)` API handed a binding to the unwrapped item so that any
mutations in the sheet would be instantly observable by the parent:

```swift
.sheet(item: $model.editingItem) { $item in
  EditItemView(item: $item)
}
```

However, this is not the API exposed to us from SwiftUI.

#### Imprecise alert and confirmation dialog APIs

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

#### Driving navigation from enum state

And the fourth problem is that while optional state is a great way to drive navigation, it
doesn't scale to multiple navigation destinations.

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
Instead, it is more concise to model the 4 destinations as an enum with a case for each 
destination, and then hold onto a single optional value to represent which destination is 
currently active:

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
to have both an "add" and "duplicate" screen presented at the same time. But sadly SwiftUI does not
come with the tools necessary to drive navigation off of an optional enum. 

These problems are what motivated the creation of this library. It provides tools that fix
each one of these problems, allowing you to model your domains as precisely as possible.

## SwiftUINavigation's tools

The tools that ship with this library aim to solve the problems discussed above and more. There are
new APIs for sheets, popovers, covers, alerts, confirmation dialogs, _and_ navigation stack
destinations that allow you to model destinations as an enum and drive navigation by a particular
case of the enum.


#### Identifiable requirement

This library comes with new versions of SwiftUI's navigation APIs (e.g. `sheet`, `popover`, etc.)
that allow you to specify the identity of the presented item via an `id` key path, just as 
`ForEach` works.

So, if you want to quickly present an item without going through the steps to explicitly conform
to `Identifiable`, you can do the following:

```swift
.sheet(item: $model.item, id: \.name) { item in
  ItemDetailView(item: item)
}
```

#### Passing bindings to child views

The library also comes with new versions of SwiftUI's navigation APIs that allow you to derive
a binding to the unwrapped item so that you can hand it off to a child view:

```swift
.sheet(item: $model.item) { $item in
  EditItemView(item: $item)
}
```

#### Imprecise alert and confirmation dialog APIs

The library provides a new set of `alert` and `confirmationDialog` view modifiers that allows one
to drive the display of those views via a single piece of optional state, rather than a binding
of a boolean _and_ a piece of optional state. And further, one can customize the title of the 
views with the unwrapped state:

```swift
.alert(item: $item) { item in
  Text("Delete \(item.name)"?)
} actions: { item in
  Button("Nevermind", role: .cancel)
  Button("Delete", role: .destructive)
}
```

#### Driving navigation from enum state

The library provides tools that allow you to power navigation from enum state. For example, suppose
your feature can present a sheet for adding an item, present a popover for duplicating an item,
and drill-down to a view for editing an item. One can represent this with an enum and a single
piece of optional state:

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

We can use SwiftUI's regular navigation APIs to navigate from this optional enum state, but we
first must annotate the `Destination` enum with the `@CasePathable` macro:

```diff
+@CasePathable
 enum Destination {
   // ...
 }
```

This allows one to refer to the cases of the enum using dot-syntax just like one refers to
properties of a struct.

With that done we can now make use of SwiftUI's navigation APIs by simply dot-chaining onto the
`destination` property and then the case we want to isolate for navigation:

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

That is the basics of using this library's APIs for driving navigation off of state. Learn more by
reading the articles below.
