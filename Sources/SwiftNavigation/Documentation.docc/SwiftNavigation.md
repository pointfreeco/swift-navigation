# ``SwiftNavigation``

Tools for making navigation in Swift applications simpler, more precise, and more ergonomic.

## Overview

This library contains a suite of tools that form the foundation for building powerful state
management and navigation APIs for Apple platforms, such as SwiftUI, UIKit, AppKit, and on non-Apple 
platforms, such as Windows, Linux, Wasm and more.

The SwiftNavigation library forms the foundation that more advanced tools can be built upon, such
as the UIKitNavigation and SwiftUINavigation libraries. There are two primary tools provided:

* ``observe(_:)``: Minimally observe changes in a model.
* ``UIBinding``: Two-way binding for connecting navigation and UI components to an observable model.

In addition to these tools there are some supplementary concepts that allow you to build more 
powerful tools, such as ``UITransaction``, which associates animations and other data with state
changes, and ``UINavigationPath``, which is a type-erased stack of data that helps in describing
stack-based navigation.

All of these tools form the foundation for how one can build more powerful and robust tools for
SwiftUI, UIKit, AppKit, and even non-Apple platforms:

#### SwiftUI

> Important: To get access to the tools described below you must depend on the SwiftUINavigation 
> package and import SwiftUINavigation.

SwiftUI already comes with incredibly powerful navigation APIs, but there are a few areas lacking
that can be filled. In particular, driving navigation from enum state so that you can have
compile-time guarantees that only one destination can be active at a time.

For example, suppose you have a feature that can present a sheet for creating an item,
drill-down to a view for editing an item, and can present an alert for confirming to delete an
item. One can technically model this with 3 separate optionals:

```swift
@Observable
class FeatureModel {
  var addItem: AddItemModel?
  var deleteItemAlertIsPresented: Bool
  var editItem: EditItemModel?
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
These 3 optionals means that there is technically 8 different states: All can be `nil`, one can
be non-`nil`, two could be non-`nil`, or all three could be non-`nil`. But only 4 of those states
are valid: either all are `nil` or exactly one is non-`nil`.

By allowing these 4 other invalid states we can accidentally tell SwiftUI to both present a sheet
and alert at the same time. But that is not a valid thing to do in SwiftUI, and SwiftUI will even
print a message to the console letting you know that in the future it may actually crash your
app.

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
active at a time. However, SwiftUI does not come with the tools to drive navigation from this 
model. This is where the SwiftUINavigation becomes useful.

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
into a `Binding<Bool>`.

We now have a concise way of describing all of the destinations a feature can navigate to, and
we can still use SwiftUI's navigation APIs.

#### UIKit

> Important: To get access to the tools described below you must depend on the UIKitNavigation 
package and import UIKitNavigation.

Unlike SwiftUI, UIKit does not come with state-driven navigation tools. Its navigation tools are
"fire-and-forget", meaning you simply invoke a method to trigger a navigation, but there is 
no representation of that even in your feature's state.

For example, to present a sheet from a button press one can simply do:

```swift
let button = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
  present(SettingsViewController(), animated: true)
})
```

This makes it easy to get started with navigation, but as SwiftUI has taught us, it is incredibly
powerful to be able to drive navigation from state. It allows you to encapsulate more of your 
feature's logic in an isolated and testable domain, and it unlocks deep linking for free since
one just needs to construct a piece of state that represents where you want to navigate to, hand
it to SwiftUI, and let SwiftUI handle the rest.

The UIKitNavigation library brings a powerful suite of navigation tools to UIKit that are heavily
inspired by SwiftUI. For example, if you have a feature model like the one discussed above in
the <doc:SwiftNavigation#SwiftUI> section:

```swift
@Observable
class FeatureeModel {
  var destination: Destination?

  enum Destination {
    case addItem(AddItemModel)
    case deleteItemAlert
    case editItem(EditItemModel)
  }
}
```

…then one can drive navigation to 

```swift
class FeatureViewController: UIViewController {
  @UIBindable var model: FeatureModel

  func viewDidLoad() {
    super.viewDidLoad()

    // Set up view hierarchy

    present(item: $model.destination.addItem) { addItemModel in
      AddItemViewController(model: addItemModel)
    }
    present(isPresented: Binding($model.destination.deleteItemAlert)) {
      let alert = UIAlertController(title: "Delete?", message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Yes", style: .destructive))
      alert.addAction(UIAlertAction(title: "No", style: .cancel))
      return alert
    }
    navigationDestination(item: $model.destination.editItem) { editItemModel in
      EditItemViewController(model: editItemModel)
    }
  }
}
```

By using the libraries navigation tools we can be guaranteed that the model will be kept in sync
with the view. When the state becomes non-`nil` the corresponding form of navigation will be 
triggered, and when the presented view is dismissed, the state will be `nil`'d out.

All of these tools are built on top of Swift's powerful Observation framework. However, that 
framework only works on newer versions of Apple's platforms: iOS 17+, macOS 14+, tvOS 17+ and
watchOS 10+. However, thanks to our backport of Swift's observation tools (see 
[Perception](http://github.com/pointfreeco/swift-perception)), you can make use of our tools 
right away, going all the way back to iOS 13.

#### Non-Apple platforms

These tools can also form the foundation of building navigation tools for non-Apple platforms, 
such as Windows, Linux, Wasm and more. We do not currently provide any such tools at this moment,
but it is possible for them to be built externally.

For example, in Wasm it is possible to use the ``observe(_:)`` function to observe changes to a 
model and update the DOM:

```swift
import JavaScriptKit

var countLabel = document.createElement("span")
_ = document.body.appendChild(countLabel)

let token = observe { _ in
  countLabel.innerText = .string("Count: \(model.count)")
}
```

And it's possible to drive navigation from state, such as an alert:

```swift
alert(isPresented: $model.isAlertPresented) // TODO
```

## Topics

### Essentials

- <doc:WhatIsNavigation>
- <doc:SwiftUINavigationTools>
- <doc:UIKitNavigationTools>

### Observing changes to state

- ``observe(_:)``
- ``ObservationToken``

### Creating and sharing state

- ``UIBindable``
- ``UIBinding``

### Attaching data to mutations

- ``withUITransaction(_:_:)``
- ``withUITransaction(_:_:_:)``
- ``UITransaction``
- ``UITransactionKey``

### Stack-based navigation

- ``UINavigationPath``
- ``HashableObject``
