# ``SwiftUINavigation``

Tools for making SwiftUI navigation simpler, more ergonomic and more precise.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swift-navigation)
- [Discussions](https://github.com/pointfreeco/swift-navigation/discussions)
- [Point-Free Videos](https://www.pointfree.co/collections/swiftui/navigation)

## Overview

SwiftUI comes with many forms of navigation (tabs, alerts, dialogs, modal sheets, popovers,
navigation links, and more), and each comes with a few ways to construct them. These ways roughly
fall in two categories:

  * "Fire-and-forget": These are initializers and methods that do not take binding arguments, which
    means SwiftUI fully manages navigation state internally. This makes it is easy to get something
    on the screen quickly, but you also have no programmatic control over the navigation. Examples
    of this are the initializers on [`TabView`][TabView.init] and
    [`NavigationLink`][NavigationLink.init] that do not take a binding.

  * "State-driven": Most other initializers and methods do take a binding, which means you can
    mutate state in your domain to tell SwiftUI when it should activate or deactivate navigation.
    Using these APIs is more complicated than the "fire-and-forget" style, but doing so instantly
    gives you the ability to deep-link into any state of your application by just constructing a
    piece of data, handing it to a SwiftUI view, and letting SwiftUI handle the rest.

Navigation that is "state-driven" is the more powerful form of navigation, albeit slightly more
complicated. To wield it correctly you must be able to model your domain as concisely as possible,
and this usually means using enums.

Unfortunately, SwiftUI does not ship with all of the tools necessary to model our domains with
enums and make use of navigation APIs. This library bridges that gap by providing APIs that allow
you to model your navigation destinations as an enum, and then drive navigation by a binding
to that enum.

For example, suppose you have a feature that can present a sheet for creating an item, drill-down to
a view for editing an item, and can present an alert for confirming to delete an item. One can
technically model this with 3 separate optionals:

```swift
@Observable
class FeatureModel {
  var addItem: AddItemModel?
  var deleteItemAlertIsPresented: Bool
  var editItem: EditItemModel?
  // ...
}
```

And then in the view one can use the `sheet`, `navigationDestination` and `alert` view modifiers
to describe the type of navigation:

```swift
.sheet(item: $model.addItem) { addItemModel in
  AddItemView(model: addItemModel)
}
.alert("Delete?", isPresented: $model.deleteItemAlertIsPresented) {
  Button("Yes", role: .destructive) { /* ... */ }
  Button("No", role: .cancel) {}
}
.navigationDestination(item: $model.editItem) { editItemModel in
  EditItemModel(model: editItemModel)
}
```

This works great at first, but also introduces a lot of unnecessary complexity into your feature.
These 3 optionals means that there are technically 8 different states: All can be `nil`, one can
be non-`nil`, two could be non-`nil`, or all three could be non-`nil`. But only 4 of those states
are valid: either all are `nil` or exactly one is non-`nil`.

By allowing these 4 other invalid states we can accidentally tell SwiftUI to both present a sheet
and alert at the same time, but that is not a valid thing to do in SwiftUI. The framework will even
print a message to the console letting you know that in the future it may actually crash your app.

Luckily Swift comes with the perfect tool for dealing with this kind of situation: enums! They
allow you to concisely define a type that can be one of many cases. So, we can refactor our 3
optionals as an enum with 3 cases, and then hold onto a single piece of optional state:

```swift
@Observable
class FeatureModel {
  var destination: Destination?

  enum Destination {
    case addItem(AddItemModel)
    case deleteItemAlert
    case editItem(EditItemModel)
  }
}
```

This is more concise, and we get compile-time verification that at most one destination can be
active at a time. However, SwiftUI does not come with the tools to drive navigation from this model.
This is where the SwiftUINavigation tools becomes useful.

We start by annotating the `Destination` enum with the `@CasePathable` macro, which allows one to
refer to the cases of an enum with dot-syntax just like one does with structs and properties:

```diff
+@CasePathable
 enum Destination {
   // ...
 }
```

And now one can use simple dot-chaining syntax to derive a binding from a particular case of
the `destination` property:

```swift
.sheet(item: $model.destination.addItem) { addItemModel in
  AddItemView(model: addItemModel)
}
.alert("Delete?", isPresented: Binding($model.destination.deleteItemAlert)) {
  Button("Yes", role: .destructive) { /* ... */ }
  Button("No", role: .cancel) {}
}
.navigationDestination(item: $model.destination.editItem) { editItemModel in
  EditItemView(model: editItemModel)
}
```

> Note: For the alert we are using the special `Binding` initializer that turns a `Binding<Void?>`
> into a `Binding<Bool>`.

We now have a concise way of describing all of the destinations a feature can navigate to, and
we can still use SwiftUI's navigation APIs.

## Topics

### Tools

- <doc:SwiftUINavigationTools>
- <doc:Navigation>
- <doc:SheetsPopoversCovers>
- <doc:AlertsDialogs>
- <doc:Bindings>

## See Also

The collection of videos from [Point-Free](https://www.pointfree.co) that dive deep into the
development of the library.

* [Point-Free Videos](https://www.pointfree.co/collections/swiftui/navigation)

[NavigationLink.init]: https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:label:)-27n7s
[TabView.init]: https://developer.apple.com/documentation/swiftui/tabview/init(content:)
