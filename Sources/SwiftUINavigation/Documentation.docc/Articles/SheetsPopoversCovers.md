# Sheets, popovers, and covers

Learn how to present sheets, popovers and covers in a concise and testable manner.

## Overview

The library comes with new tools for driving sheets, popovers and covers from optional and enum 
state.

* [Sheets](#Sheets)
* [Popovers](#Popovers)
* [Covers](#Covers)

### Sheets

Suppose your view or model holds a piece of optional state that represents whether or not a modal
sheet is presented:

```swift
struct ContentView: View {
  @State var destination: Int?

  // ...
}
```

Further suppose that the screen being presented wants a binding to the integer when it is non-`nil`.
You can use the `sheet(unwrapping:)` view modifier that comes with the library:

```swift
var body: some View {
  List {
    // ...
  }
  .sheet(unwrapping: self.$destination) { $number in 
    CounterView(number: $number)
  }
}
```

Notice that the trailing closure is handed a binding to the unwrapped state. This binding can be
handed to the child view, and any changes made by the parent will be reflected in the child, and
vice-versa.

Sometimes it is not optimal to model presentation destinations as optionals. In particular, if a 
feature can navigate to multiple, mutually exclusive screens, then an enum is more appropriate.

There is an additional overload of the `sheet` for this situation. If you model your destinations
as a "case-pathable" enum:

```swift
@State var destination: Destination?

@CasePathable
enum Destination {
  case counter(Int)
  // More destinations
}
```

Then you can show a sheet from the `counter` case with the following:

```swift
var body: some View {
  List {
    // ...
  }
  .sheet(unwrapping: self.$destination.counter) { $number in 
    CounterView(number: $number)
  }
}
```

### Popovers

Popovers work similarly to covers. If the popover's state is represented as an optional you can do
the following:

```swift
struct ContentView: View {
  @State var destination: Int?

  var body: some View {
    List {
      // ...
    }
    .popover(unwrapping: self.$destination) { $number in 
      CounterView(number: $number)
    }
  }
}
```

And if the popover state is represented as a "case-pathable" enum, then you can do the following:

```swift
struct ContentView: View {
  @State var destination: Destination?

  @CasePathable
  enum Destination {
    case counter(Int)
    // More destinations
  }

  var body: some View {
    List {
      // ...
    }
    .popover(unwrapping: self.$destination.counter) { $number in 
      CounterView(number: $number)
    }
  }
}
```

### Covers

Full screen covers work similarly to covers and sheets. If the cover's state is represented as an
optional you can do the following:

```swift
struct ContentView: View {
  @State var destination: Int?

  var body: some View {
    List {
      // ...
    }
    .fullscreenCover(unwrapping: self.$destination) { $number in 
      CounterView(number: $number)
    }
  }
}
```

And if the covers' state is represented as a "case-pathable" enum, then you can do the following:

```swift
struct ContentView: View {
  @State var destination: Destination?

  @CasePathable
  enum Destination {
    case counter(Int)
    // More destinations
  }

  var body: some View {
    List {
      // ...
    }
    .fullscreenCover(unwrapping: self.$destination.counter) { $number in 
      CounterView(number: $number)
    }
  }
}
```

## Topics

### Presentation modifiers

- ``SwiftUI/View/fullScreenCover(unwrapping:onDismiss:content:)``
- ``SwiftUI/View/popover(unwrapping:attachmentAnchor:arrowEdge:content:)``
- ``SwiftUI/View/sheet(unwrapping:onDismiss:content:)``
