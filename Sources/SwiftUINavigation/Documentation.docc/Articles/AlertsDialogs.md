# Alerts and dialogs

Learn how to present alerts and confirmation dialogs in a concise and testable manner.

## Overview

The library comes with new tools for driving alerts and confirmation dialogs from optional and enum
state, and makes them more testable.

### Alerts

Suppose you have a feature for deleting something in your application and you want to show an alert
for the user to confirm the deletion. You can do this by holding onto an optional `AlertState` in
your model, as well as an enum that describes every action that can happen in the alert:


```swift
@Observable
class FeatureModel {
  var alert: AlertState<AlertAction>?
  enum AlertAction {
    case deletionConfirmed
  }

  // ...
}
```

Then, when you need to show an alert you can update the alert state with a title, message and
buttons:

```swift
func deleteButtonTapped() {
  self.alert = AlertState {
    TextState("Are you sure?")
  } actions: {
    ButtonState("Delete", action: .send(.delete))
    ButtonState("Nevermind", role: .cancel)
  } message: {
    TextState("Deleting this item cannot be undone.")
  }
}
```

The type `TextState` is closely related to `Text` from SwiftUI, but plays more nicely with
equatability. This makes it possible to write tests against these values.

> Tip: The `actions` closure is a result builder, which allows you to insert small bits of logic:
> ```swift
> } actions: {
>   if item.isLocked {
>     ButtonState("Unlock and delete", action: .send(.unlockAndDelete))
>   } else {
>     ButtonState("Delete", action: .send(.delete))
>   }
>   ButtonState("Nevermind", role: .cancel)
> }
> ```

Next you can provide an endpoint that will be called when the alert is interacted with:

```swift
func alertButtonTapped(_ action: AlertAction) {
  switch action {
  case .deletionConfirmed:
    // NB: Perform deletion logic here
  }
}
```

Finally, you can use a new, overloaded `.alert` view modifier for showing the alert when this state
becomes non-`nil`:

```swift
struct ContentView: View {
  @ObservedObject var model: FeatureModel

  var body: some View {
    List {
      // ...
    }
    .alert(unwrapping: self.$model.alert) { action in
      self.model.alertButtonTapped(action)
    }
  }
}
```

By having all of the alert's state in your feature's model, you instantly unlock the ability to test
it:

```swift
func testDelete() {
  let model = FeatureModel(…)

  model.deleteButtonTapped()
  XCTAssertEqual(model.alert?.title, TextState("Are you sure?"))

  model.alertButtonTapped(.deletionConfirmation)
  // NB: Assert that deletion actually occurred.
}
```

This works because all of the types for describing an alert are `Equatable`, including `AlertState`,
`TextState`, and even the buttons.

Sometimes it is not optimal to model the alert as an optional. In particular, if a feature can
navigate to multiple, mutually exclusive screens, then an enum is more appropriate.

In such a case:


```swift
@Observable
class FeatureModel {
  var destination: Destination?
  enum Destination {
    case alert(AlertState<AlertAction>)
    // NB: Other destinations
  }
  enum AlertAction {
    case deletionConfirmed
  }

  // ...
}
```

With this kind of set up you can use an alternative `alert` view modifier that takes an additional
argument for specifying which case of the enum drives the presentation of the alert:

```swift
.alert(unwrapping: self.$model.destination, case: /Destination.alert) { action in
  self.model.alertButtonTapped(action)
}
```

Note that the `case` argument is specified via a concept known as "case paths", which are like
key paths except tuned specifically for enums and cases rather than structs and properties. See
<doc:WhatIsNavigation> for more information.

### Confirmation dialogs

The APIs for driving confirmation dialogs from optional and enum state look nearly identical to that
of alerts.

For example, the model for a delete confirmation could look like this:

```swift
@Observable
class FeatureModel {
  var dialog: ConfirmationDialogState<DialogAction>?
  enum DialogAction {
    case deletionConfirmed
  }

  func deleteButtonTapped() {
    self.dialog = ConfirmationDialogState(
      title: TextState("Are you sure?"),
      titleVisibility: .visible,
      message: TextState("Deleting this item cannot be undone."),
      buttons: [
        .destructive(TextState("Delete"), action: .send(.delete)),
        .cancel(TextState("Nevermind")),
      ]
    )
  }

  func dialogButtonTapped(_ action: DialogAction) {
    switch action {
    case .deletionConfirmed:
      // NB: Perform deletion logic here
    }
  }
}
```

And then the view would look like this:

```swift
struct ContentView: View {
  @ObservedObject var model: FeatureModel

  var body: some View {
    List {
      // ...
    }
    .confirmationDialog(unwrapping: self.$model.dialog) { action in
      self.dialogButtonTapped(action)
    }
  }
}
```
