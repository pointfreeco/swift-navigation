# Dialogs

Learn how to present alerts and confirmation dialogs in a concise and testable manner.

## Overview

The library adds tools to drive alerts from optionally-bound state, and makes them more testable.

### Alerts

Suppose you have a feature for deleting something in your application and you want to show an alert
for the user to confirm the deletion. You can do this by holding onto an optional `ConfirmDelete` state in
your model:


```swift
@Observable
class FeatureModel {
  struct ConfirmDelete: Equatable {}

  var confirmDelete: ConfirmDelete?

  func deleteButtonTapped() {
    self.confirmDelete = .init()
  }
  
  func deleteConfirmButtonTapped() {
    // do deletion
    confirmDelete = nil
  }

  func deleteCancelButtonPressed() {
    confirmDelete = nil
  }
}
```

You can then use the `.alert()` view modifier to display the alert when the state becomes non-`nil`:

```swift
struct ContentView: View {
  @ObservedObject var model: FeatureModel

  var body: some View {
    Button("Delete Everything") {
      model.deleteButtonTapped()
    }
    List {
      // ...
    }
    .alert(self.$model.confirmDelete) {
      "Are you sure?"
    } actions: {
      Button("Delete") {
        model.deleteConfirmButtonTapped()
      }
      Button("Nevermind") {
        model.deleteCancelButtonPressed()
      }
    } message: {
      Text("Deleting this item cannot be undone.")
    }
  }
}
```

### Confirmation dialogs

Confirmation dialogs are very similar to alerts, but will always have a "dismiss" action.
However, if you provide a button with a role of `.cancel` it will take
its place. This is recommended if you want to perform any specific task when cancelling,
otherwise the bound item will simply be `nil`-ed out.

To model the previous example as a confirmation dialog, we can use the built-in dismiss action, and
declare it the view like so:

```swift
struct ContentView: View {
  @ObservedObject var model: FeatureModel

  var body: some View {
    Button("Delete Everything") {
      model.deleteButtonTapped()
    }
    List {
      // ...
    }
    .confirmationDialog(self.$model.confirmDelete) {
      "Are you sure?"
    } actions: {
      Button("Delete") {
        model.deleteConfirmButtonTapped()
      }
    } message: {
      Text("Deleting this item cannot be undone.")
    }
  }
}
```

Instead of `Nevermind`, there will be a `Cancel` button. Note that the `deleteCancelButtonPressed()` function is no
longer called, and could be removed from the model.
