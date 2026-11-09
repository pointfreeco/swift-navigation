# Stack navigation with AppKitPlus

Drive a stack of view controllers from state, push destinations from optional state, and let
content that a binding showed close itself.

## Overview

AppKit has no navigation controller. With the package's `AppKitPlus` trait, AppKitNavigation builds
on the `NSNavigationController` of
[AppKitPlus](https://github.com/AppKitSupportProgram/AppKitPlus-Release) to offer what
UIKitNavigation offers on UIKit:

- ``NavigationStackController``, whose stack follows a path of data;
- `navigationDestination(isPresented:)` and `navigationDestination(item:)`, which push a view
  controller while optional state holds a value;
- `traitCollection.dismiss()`, with which pushed and presented content closes itself;
- selection bindings for tables and outlines driven by AppKitPlus's diffable data sources.

### Turning the trait on

The trait is off by default, and with it off the package neither fetches AppKitPlus nor offers
these APIs. Turn it on where you depend on the package, and name the default traits too: naming
any trait replaces them, and AppKitNavigation needs them.

```swift
.package(
  url: "https://github.com/MxIris-Library-Forks/swift-navigation",
  from: "…",  // a version that has the AppKitPlus trait
  traits: [.defaults, "AppKitPlus"]
)
```

In an Xcode project, turn the trait on for the package in the project's Package Dependencies
(Xcode 26.4 or later), together with the default traits.

The trait needs Swift 6.2 or later and macOS 12 or later. It adds AppKitPlus-Release 0.21.0 or
later to your app; AppKitPlus is a dynamic framework that the app embeds.

### A stack driven by a path

The path holds data rather than view controllers. Register how each type of data is shown, and
push by appending to the path, or with the `push` trait from inside the stack:

```swift
let stackController = NavigationStackController(path: $model.path) {
  PlanetListViewController(model: model)
}

// In PlanetListViewController.viewDidLoad():
navigationDestination(for: Planet.self) { planet in
  PlanetViewController(planet: planet)
}

// Anywhere inside the stack:
traitCollection.push(value: Planet.mars)
```

When the user goes back with the back button, ⌘↑ or a swipe, the path loses the elements whose view
controllers were popped. A path of mixed types can use `UINavigationPath`.

### Pushing from optional state

A view controller in a navigation controller can push a destination while optional state holds a
value, the way it presents one with `present(item:style:)`:

```swift
navigationDestination(item: $model.selectedPlanet) { planet in
  PlanetViewController(planet: planet)
}
```

Setting the state to `nil` pops the destination; going back past it sets the state to `nil`. A new
item, told apart by its identity, replaces the destination once the old one has left the screen.

### Content that dismisses itself

Content that a binding pushed or presented — with `navigationDestination`, `present`, `sheet`,
`modal`, `modalSession` or `popover` — can close itself without knowing how it was shown:

```swift
doneButton.addAction { [weak self] _ in
  self?.traitCollection.dismiss()
}
```

It ends as if the user had closed it: the binding is set to `nil`, and `onDismiss` runs once the
content has left the screen.

### Things to know

- A ``NavigationStackController`` puts a proxy in front of the delegate you set, so that the path
  learns of the view controllers the user pops. The proxy passes every message on to your
  delegate; reading `delegate` returns the proxy.
- AppKitPlus hands traits down to the view controllers inside on the next turn of the run loop, so
  `push` and `dismiss` are there once a view controller is on screen.
- Pushes and pops are animated unless the change happens in a transaction that disables
  animations.

## Topics

### Stacks

- ``NavigationStackController``
- ``AppKitPushAction``

### Dismissing

- ``AppKitDismissAction``
