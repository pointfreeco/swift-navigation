# Swift Navigation

[![CI](https://github.com/pointfreeco/swift-navigation/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swift-navigation/actions/workflows/ci.yml)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](http://pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-navigation%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-navigation)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-navigation%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-navigation)

Bringing simple and powerful navigation tools to all Swift platforms, inspired by SwiftUI.

## Overview

This library contains a suite of tools that form the foundation for building powerful state
management and navigation APIs for Apple platforms, such as SwiftUI, UIKit, and AppKit, as well as
for non-Apple platforms, such as Windows, Linux, Wasm, and more.

The SwiftNavigation library forms the foundation that more advanced tools can be built upon, such
as the UIKitNavigation and SwiftUINavigation libraries. There are two primary tools provided:

* `observe`: Minimally observe changes in a model.
* `UIBinding`: Two-way binding for connecting navigation and UI components to an observable model.

In addition to these tools there are some supplementary concepts that allow you to build more 
powerful tools, such as `UITransaction`, which associates animations and other data with state
changes, and `UINavigationPath`, which is a type-erased stack of data that helps in describing
stack-based navigation.

All of these tools form the foundation for how one can build more powerful and robust tools for
SwiftUI, UIKit, AppKit, and even non-Apple platforms.

#### SwiftUI

> [!IMPORTANT]
> To get access to the tools described below you must depend on the SwiftNavigation package and
> import the SwiftUINavigation library.

SwiftUI already comes with incredibly powerful navigation APIs, but there are a few areas lacking
that can be filled. In particular, driving navigation from enum state so that you can have
compile-time guarantees that only one destination can be active at a time.

For example, suppose you have a feature that can present a sheet for creating an item, drill-down to
a view for editing an item, and can present an alert for confirming to delete an item. One can
technically model this with 3 separate optionals:

```swift
@Observable
class FeatureModel {
  var addItem: AddItemModel?
  var deleteItemAlertIsPresented: Bool
  var editItem: EditItemModel?
}
```

And then in the view one can use the `sheet`, `navigationDestination` and `alert` view modifiers to
describe the type of navigation:

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
and alert at the same time, but that is not a valid thing to do in SwiftUI, and SwiftUI will even
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
active at a time. However, SwiftUI does not come with the tools to drive navigation from this 
model. This is where the SwiftUINavigation tools becomes useful.

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

> [!NOTE]
> For the alert we are using the special `Binding` initializer that turns a `Binding<Void?>` into a
> `Binding<Bool>`.

We now have a concise way of describing all of the destinations a feature can navigate to, and
we can still use SwiftUI's navigation APIs.

#### UIKit

> [!IMPORTANT]
> To get access to the tools described below you must depend on the SwiftNavigation package and
> import the UIKitNavigation library.

Unlike SwiftUI, UIKit does not come with state-driven navigation tools. Its navigation tools are
"fire-and-forget", meaning you simply invoke a method to trigger a navigation, but there is 
no representation of that in your feature's state.

For example, to present a sheet from a button press one can simply do:

```swift
let button = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
  present(SettingsViewController(), animated: true)
})
```

This makes it easy to get started with navigation, but as SwiftUI has taught us, it is incredibly
powerful to be able to drive navigation from state. It allows you to encapsulate more of your 
feature's logic in an isolated and testable domain, and it unlocks deep linking for free since one
just needs to construct a piece of state that represents where you want to navigate to, hand it to
SwiftUI, and let SwiftUI handle the rest.

The UIKitNavigation library brings a powerful suite of navigation tools to UIKit that are heavily
inspired by SwiftUI. For example, if you have a feature model like the one discussed above in
the [SwiftUI](#swiftui) section:

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

…then one can drive navigation in a _view controller_ using tools in the library: 

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

Another powerful aspect of SwiftUI is its ability to update its UI whenever state in an observable
model changes. And thanks to Swift's observation tools this can be done implicitly and 
minimally: whichever fields are accessed in the `body` of the view are automatically tracked 
so that when they change the view updates.

Our UIKitNavigation library comes with a tool that brings this power to UIKit, and it's called
`observe`:

```swift
observe { [weak self] in
  guard let self else { return }
  
  countLabel.text = "Count: \(model.count)"
  factLabel.isHidden = model.fact == nil 
  if let fact = model.fact {
    factLabel.text = fact
  }
  activityIndicator.isHidden = !model.isLoadingFact
}
```

Whichever fields are accessed inside `observe` (such as `count`, `fact` and `isLoadingFact` above)
are automatically tracked, so that whenever they are mutated the trailing closure of `observe`
will be invoked again, allowing us to update the UI with the freshest data.

All of these tools are built on top of Swift's powerful Observation framework. However, that 
framework only works on newer versions of Apple's platforms: iOS 17+, macOS 14+, tvOS 17+ and
watchOS 10+. However, thanks to our back-port of Swift's observation tools (see 
[Perception](http://github.com/pointfreeco/swift-perception)), you can make use of our tools 
right away, going all the way back to the iOS 13 era of platforms.

#### Non-Apple platforms

The tools provided by this library can also form the foundation of building navigation tools for
non-Apple platforms, such as Windows, Linux, Wasm and more. We do not currently provide any such
tools at this moment, but it is possible for them to be built externally.

For example, in Wasm it is possible to use the `observe(isolation:_:)` function to observe changes
to a model and update the DOM:

```swift
import JavaScriptKit

var countLabel = document.createElement("span")
_ = document.body.appendChild(countLabel)

let token = observe {
  countLabel.innerText = .string("Count: \(model.count)")
}
```

And it's possible to drive navigation from state, such as an alert:

```swift
alert(isPresented: $model.isShowingErrorAlert) {
  "Something went wrong"
}
```

And you can build more advanced tools for presenting and dismissing `<dialog>`'s in the browser.
  
## Examples

This repo comes with lots of examples to demonstrate how to solve common and complex navigation 
problems with the library. Check out [this](./Examples) directory to see them all, including:

  * [Case Studies](./Examples/CaseStudies): A collection of SwiftUI and UIKit case studies
    demonstrating this library's APIs.
  * [Inventory](./Examples/Inventory): A multi-screen application with lists, sheets, popovers and 
    alerts, all driven by state and deep-linkable.

## Learn More

Swift Navigation's tools were motivated and designed over the course of many episodes on
[Point-Free](https://www.pointfree.co), a video series exploring functional programming and the 
Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and
[Stephen Celis](https://twitter.com/stephencelis).

You can watch all of the episodes [here](https://www.pointfree.co/collections/swiftui/navigation).

<a href="https://www.pointfree.co/collections/swiftui/navigation">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/email-assets/pf-email-header.png" width="600">
</a>

## Community

If you want to discuss this library or have a question about how to use it to solve a particular
problem, there are a number of places you can discuss with fellow
[Point-Free](http://www.pointfree.co) enthusiasts:

  * For long-form discussions, we recommend the
    [discussions](http://github.com/pointfreeco/swift-navigation/discussions) tab of this repo.
  * For casual chat, we recommend the
    [Point-Free Community slack](http://pointfree.co/slack-invite).

## Installation

You can add Swift Navigation to an Xcode project by adding it as a package dependency.

> https://github.com/pointfreeco/swift-navigation

If you want to use Swift Navigation in a [SwiftPM](https://swift.org/package-manager/) project, 
it's as simple as adding it to a `dependencies` clause in your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.0.0")
]
```

## Documentation

The latest documentation for the Swift Navigation APIs is available
[here](https://swiftpackageindex.com/pointfreeco/swift-navigation/main/documentation/swiftnavigation).

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
