# Destructuring views

Learn how to use ``IfLet``, ``IfCaseLet`` and ``Switch`` views in order to destructure bindings into
smaller parts.

## Overview

Often our views can hold bindings of optional and enum state, and we will want to derive a binding
to its underlying wrapped value or a particular case. SwiftUI does not come with tools to do this,
but this library has a few views for accomplishing this.

### IfLet

The ``IfLet`` view allows one to derive a binding of an honest value from a binding of an optional
value. For example, suppose you had an interface that could editing a single piece of text in the
UI, and further those changes can be either saved or discarded.

Using ``IfLet`` you can model the state of being in editing mode as an optional string:

```swift
struct EditView: View {
  @State var string: String = ""
  @State var editableString: String?

  var body: some View {
    Form {
      IfLet(self.$editableString) { $string in
        TextField("Edit string", text: $string)
        HStack {
          Button("Cancel") {
            self.editableString = nil
          }
          Button("Save") {
            self.string = string
            self.editableString = nil
          }
        }
      } else: {
        Text(self.string)
        Button("Edit") {
          self.editableString = self.string
        }
      }
      .buttonStyle(.borderless)
    }
  }
}
```

This is the most optimal way to model this domain. Without the ability to derive a 
`Binding<String>` from a `Binding<String?>` we would have had to hold onto extra state to represent
whether or not we are in editing mode:

```swift
struct EditView: View {
  @State var string: String = ""
  @State var editableString: String
  @State var isEditing = false

  // ...
}
```

This is non-optimal because we have to make sure to clean up `editableString` before or after
showing the editable `TextField`. If we forget to do that we can introduce bugs into our 
application, such as showing the _previous_ editing string when entering edit mode.

### IfCaseLet

The ``IfCaseLet`` view is similar to ``IfLet`` (see [above](#IfLet)), except it can derive a binding
to a particular case of an enum.

For example, using the sample code from [above](#IfLet), what if you didn't want to use an optional
string for `editableState`, but instead use a custom enum so that you can describe the two states 
more clearly:

```swift
enum EditableString {
  case active(String)
  case inactive
}
```

You cannot use ``IfLet`` with this because it's an enum, but you can use ``IfCaseLet``:

```swift
struct EditView: View {
  @State var string: String = ""
  @State var editableString: EditableString = .inactive

  var body: some View {
    Form {
      IfCaseLet(self.$editableString, pattern: /EditableString.active) { $string in
        TextField("Edit string", text: $string)
        HStack {
          Button("Cancel") {
            self.editableString = .inactive
          }
          Button("Save") {
            self.string = string
            self.editableString = .inactive
          }
        }
      } else: {
        Text(self.string)
        Button("Edit") {
          self.editableString = .active(self.string)
        }
      }
      .buttonStyle(.borderless)
    }
  }
}
```

The "pattern" for the ``IfCaseLet`` is expressed by what is known as a "[case path][case-paths-gh]". 
A case path is like a key path, except it is specifically tuned for abstracting over the
shape of enums rather than structs. A key path abstractly bundles up the functionality of getting 
and setting a property on a struct, whereas a case path bundles up the functionality of "extracting"
a value from an enum and "embedding" a value into an enum. They are an indispensable tool for 
transforming bindings.

### Switch and CaseLet

The ``Switch`` and ``CaseLet`` generalize the ``IfLet`` and ``IfCaseLet`` views, allowing you to 
destructure a binding of an enum into bindings of each case, and provides some runtime exhaustivity
checking.

For example, a warehousing application may model the status of an inventory item using an enum
with cases that distinguish in-stock and out-of-stock statuses. ``Switch`` and ``CaseLet`` can
be used to produce bindings to the associated values of each case.

```swift
enum ItemStatus {
  case inStock(quantity: Int)
  case outOfStock(isOnBackOrder: Bool)
}

struct InventoryItemView: View {
  @State var status: ItemStatus

  var body: some View {
    Switch(self.$status) {
      CaseLet(/ItemStatus.inStock) { $quantity in
        HStack {
          Text("Quantity: \(quantity)")
          Stepper("Quantity", value: $quantity)
        }
        Button("Out of stock") { self.status = .outOfStock(isOnBackOrder: false) }
      }
      CaseLet(/ItemStatus.outOfStock) { $isOnBackOrder in
        Toggle("Is on back order?", isOn: $isOnBackOrder)
        Button("In stock") { self.status = .inStock(quantity: 1) }
      }
    }
  }
}
```

In debug builds, exhaustivity is handled at runtime: if the `Switch` encounters an
unhandled case, and no ``Default`` view is present, a runtime warning is issued and a warning
view is presented.

[case-paths-gh]: http://github.com/pointfreeco/swift-case-paths
