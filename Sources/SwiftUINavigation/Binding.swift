#if canImport(SwiftUI)
  import SwiftUI

  extension Binding {
    /// Creates a binding by projecting the base value to an unwrapped value.
    ///
    /// Useful for producing non-optional bindings from optional ones.
    ///
    /// See ``IfLet`` for a view builder-friendly version of this initializer.
    ///
    /// > Note: SwiftUI comes with an equivalent failable initializer, `Binding.init(_:)`, but using
    /// > it can lead to crashes at runtime. [Feedback][FB8367784] has been filed, but in the meantime
    /// > this initializer exists as a workaround.
    ///
    /// [FB8367784]: https://gist.github.com/stephencelis/3a232a1b718bab0ae1127ebd5fcf6f97
    ///
    /// - Parameter base: A value to project to an unwrapped value.
    /// - Returns: A new binding or `nil` when `base` is `nil`.
    public init?(unwrapping base: Binding<Value?>) {
      self.init(unwrapping: base, case: /Optional.some)
    }

    /// Creates a binding by projecting the base enum value to an unwrapped case.
    ///
    /// Useful for extracting bindings of non-optional state from the case of an enum.
    ///
    /// See ``IfCaseLet`` for a view builder-friendly version of this initializer.
    ///
    /// - Parameters:
    ///   - enum: An enum to project to a particular case.
    ///   - casePath: A case path that identifies a particular case to unwrap.
    /// - Returns: A new binding or `nil` when `base` is `nil`.
    public init?<Enum>(unwrapping enum: Binding<Enum>, case casePath: CasePath<Enum, Value>) {
      guard var `case` = casePath.extract(from: `enum`.wrappedValue)
      else { return nil }

      self.init(
        get: {
          `case` = casePath.extract(from: `enum`.wrappedValue) ?? `case`
          return `case`
        },
        set: {
          guard casePath.extract(from: `enum`.wrappedValue) != nil else { return }
          `case` = $0
          `enum`.transaction($1).wrappedValue = casePath.embed($0)
        }
      )
    }

    /// Creates a binding by projecting the current optional enum value to the value at a particular
    /// case.
    ///
    /// > Note: This method is constrained to optionals so that the projected value can write `nil`
    /// > back to the parent, which is useful for navigation, particularly dismissal.
    ///
    /// - Parameter casePath: A case path that identifies a particular case to unwrap.
    /// - Returns: A binding to an enum case.
    public func `case`<Enum, Case>(_ casePath: CasePath<Enum, Case>) -> Binding<Case?>
    where Value == Enum? {
      .init(
        get: { self.wrappedValue.flatMap(casePath.extract(from:)) },
        set: { newValue, transaction in
          self.transaction(transaction).wrappedValue = newValue.map(casePath.embed)
        }
      )
    }

    /// Creates a binding by projecting the current optional value to a boolean describing if it's
    /// non-`nil`.
    ///
    /// Writing `false` to the binding will `nil` out the base value. Writing `true` does nothing.
    ///
    /// - Returns: A binding to a boolean. Returns `true` if non-`nil`, otherwise `false`.
    public func isPresent<Wrapped>() -> Binding<Bool>
    where Value == Wrapped? {
      .init(
        get: { self.wrappedValue != nil },
        set: { isPresent, transaction in
          if !isPresent {
            self.transaction(transaction).wrappedValue = nil
          }
        }
      )
    }

    /// Creates a binding by projecting the current optional enum value to a boolean describing
    /// whether or not it matches the given case path.
    ///
    /// Writing `false` to the binding will `nil` out the base enum value. Writing `true` does
    /// nothing.
    ///
    /// Useful for interacting with APIs that take a binding of a boolean that you want to drive with
    /// with an enum case that has no associated data.
    ///
    /// For example, a view may model all of its presentations in a single destination enum to prevent
    /// the invalid states that can be introduced by holding onto many booleans and optionals,
    /// instead. Even the simple case of two booleans driving two alerts introduces a potential
    /// runtime state where both alerts are presented at the same time. By modeling these alerts
    /// using a two-case enum instead of two booleans, we can eliminate this invalid state at compile
    /// time. Then we can transform a binding to the destination enum into a boolean binding using
    /// `isPresent`, so that it can be passed to various presentation APIs.
    ///
    /// ```swift
    /// enum Destination {
    ///   case deleteAlert
    ///   ...
    /// }
    ///
    /// struct ProductView: View {
    ///   @State var destination: Destination?
    ///   @State var product: Product
    ///
    ///   var body: some View {
    ///     Button("Delete") {
    ///       self.model.destination = .deleteAlert
    ///     }
    ///     // SwiftUI's vanilla alert modifier
    ///     .alert(
    ///       self.product.name
    ///       isPresented: self.$model.destination.isPresent(/Destination.deleteAlert),
    ///       actions: {
    ///         Button("Delete", role: .destructive) {
    ///           self.model.deleteConfirmationButtonTapped()
    ///         }
    ///       },
    ///       message: {
    ///         Text("Are you sure you want to delete this product?")
    ///       }
    ///     )
    ///   }
    /// }
    /// ```
    ///
    /// - Parameter casePath: A case path that identifies a particular case to match.
    /// - Returns: A binding to a boolean.
    public func isPresent<Enum, Case>(_ casePath: CasePath<Enum, Case>) -> Binding<Bool>
    where Value == Enum? {
      self.case(casePath).isPresent()
    }

    /// Creates a binding that ignores writes to its wrapped value when equivalent to the new value.
    ///
    /// Useful to minimize writes to bindings passed to SwiftUI APIs. For example, [`NavigationLink`
    /// may write `nil` twice][FB9404926] when dismissing its destination via the navigation bar's
    /// back button. Logic attached to this dismissal will execute twice, which may not be desirable.
    ///
    /// [FB9404926]: https://gist.github.com/mbrandonw/70df235e42d505b3b1b9b7d0d006b049
    ///
    /// - Parameter isDuplicate: A closure to evaluate whether two elements are equivalent, for
    ///   purposes of filtering writes. Return `true` from this closure to indicate that the second
    ///   element is a duplicate of the first.
    public func removeDuplicates(by isDuplicate: @escaping (Value, Value) -> Bool) -> Self {
      .init(
        get: { self.wrappedValue },
        set: { newValue, transaction in
          guard !isDuplicate(self.wrappedValue, newValue) else { return }
          self.transaction(transaction).wrappedValue = newValue
        }
      )
    }
  }

  extension Binding where Value: Equatable {
    /// Creates a binding that ignores writes to its wrapped value when equivalent to the new value.
    ///
    /// Useful to minimize writes to bindings passed to SwiftUI APIs. For example, [`NavigationLink`
    /// may write `nil` twice][FB9404926] when dismissing its destination via the navigation bar's
    /// back button. Logic attached to this dismissal will execute twice, which may not be desirable.
    ///
    /// [FB9404926]: https://gist.github.com/mbrandonw/70df235e42d505b3b1b9b7d0d006b049
    public func removeDuplicates() -> Self {
      self.removeDuplicates(by: ==)
    }
  }

  extension Binding {
    public func _printChanges(_ prefix: String = "") -> Self {
      Self(
        get: { self.wrappedValue },
        set: { newValue, transaction in
          var oldDescription = ""
          debugPrint(self.wrappedValue, terminator: "", to: &oldDescription)
          var newDescription = ""
          debugPrint(newValue, terminator: "", to: &newDescription)
          print("\(prefix.isEmpty ? "\(Self.self)" : prefix):", oldDescription, "=", newDescription)
          self.transaction(transaction).wrappedValue = newValue
        }
      )
    }
  }
#endif  // canImport(SwiftUI)
