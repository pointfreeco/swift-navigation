# Navigation links and destinations

Learn how to drive navigation in `NavigationView` and `NavigationStack` in a concise and testable
manner.

## Overview

The library comes with new tools for driving drill-down navigation with optional and enum values.
This includes new initializers on `NavigationLink` and new overloads of the `navigationDestination`
view modifier.

Suppose your view or model holds a piece of optional state that represents whether or not a 
drill-down should occur:

```swift
struct ContentView: View {
  @State var destination: Int?

  // ...
}
```

Further suppose that the screen being navigated to wants a binding to the integer when it is 
non-`nil`. You can construct a `NavigationLink` that will activate when that state becomes 
non-`nil`, and will deactivate when the state becomes `nil`:

```swift
NavigationLink(unwrapping: self.$destination) { isActive in
  self.destination = isActive ? 42 : nil
} destination: { $number in 
  CounterView(number: $number)
} label: {
  Text("Go to counter")
}
```

The first trailing closure is the "action" of the navigation link. It is invoked with `true` when
the user taps on the link, and it is invoked with `false` when the user taps the back button or
swipes on the left edge of the screen. It is your job to hydrate the state in the action closure.

The second trailing closure, labeled `destination`, takes an argument that is the binding of the
unwrapped state. This binding can be handed to the child view, and any changes made by the parent
will be reflected in the child, and vice-versa.

For iOS 16+ you can use the `navigationDestination` overload:

```swift
Button {
  self.destination = 42
} label: {
  Text("Go to counter")
}
.navigationDestination(
  unwrapping: self.$model.destination
) { $item in 
  CounterView(number: $number)
}
```

Sometimes it is not optimal to model navigation destinations as optionals. In particular, if a
feature can navigate to multiple, mutually exclusive screens, then an enum is more appropriate.

Suppose that in addition to be able to drill down to a counter view that one can also open a 
sheet with some text. We can model those destinations as an enum:

```swift
@CasePathable
enum Destination {
  case counter(Int)
  case text(String)
}
```

> Note: We have applied the `@CasePathable` macro from
> [CasePaths](https://github.com/pointfreeco.swift-case-paths), which allows the navigation binding
> to use "dynamic case lookup" to a particular enum case.

And we can hold an optional destination in state to represent whether or not we are navigated to
one of these destinations:

```swift
@State var destination: Destination?
```

With this set up you can make use of the
``SwiftUI/NavigationLink/init(unwrapping:onNavigate:destination:label:)`` initializer on
`NavigationLink` in order to specify a binding to the optional destination, and further specify
which case of the enum you want driving navigation:

```swift
NavigationLink(unwrapping: self.$destination.counter) { isActive in
  self.destination = isActive ? .counter(42) : nil
} destination: { $number in 
  CounterView(number: $number)
} label: {
  Text("Go to counter")
}
```

And similarly for ``SwiftUI/View/navigationDestination(unwrapping:destination:)``:

```swift
Button {
  self.destination = .counter(42)
} label: {
  Text("Go to counter")
}
.navigationDestination(unwrapping: self.$model.destination.counter) { $number in 
  CounterView(number: $number)
}
```

## Topics

### Navigation views and modifiers

- ``SwiftUI/View/navigationDestination(unwrapping:destination:)``
- ``SwiftUI/NavigationLink/init(unwrapping:onNavigate:destination:label:)``

### Supporting types

- ``HashableObject``
