#if canImport(SwiftUI)
  import CasePaths
  import SwiftUI

  extension Binding {
    #if swift(>=5.9)
      /// Returns a binding to the associated value of a given case key path.
      ///
      /// Useful for producing bindings to values held in enum state.
      ///
      /// - Parameter keyPath: A case key path to a specific associated value.
      /// - Returns: A new binding.
      public subscript<Member>(
        dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
      ) -> Binding<Member>?
      where Value: CasePathable {
        Binding<Member>(unwrapping: self[keyPath])
      }

      /// Returns a binding to the associated value of a given case key path.
      ///
      /// Useful for driving navigation off an optional enumeration of destinations.
      ///
      /// - Parameter keyPath: A case key path to a specific associated value.
      /// - Returns: A new binding.
      public subscript<Enum: CasePathable, Member>(
        dynamicMember keyPath: KeyPath<Enum.AllCasePaths, AnyCasePath<Enum, Member>>
      ) -> Binding<Member?>
      where Value == Enum? {
        self[keyPath]
      }
    #endif

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
      guard let value = base.wrappedValue else { return nil }
      self = base[default: DefaultSubscript(value)]
    }

    /// Creates a binding by projecting the current optional value to a boolean describing if it's
    /// non-`nil`.
    ///
    /// Writing `false` to the binding will `nil` out the base value. Writing `true` does nothing.
    ///
    /// - Returns: A binding to a boolean. Returns `true` if non-`nil`, otherwise `false`.
    public func isPresent<Wrapped>() -> Binding<Bool>
    where Value == Wrapped? {
      self._isPresent
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

  extension Optional {
    fileprivate var _isPresent: Bool {
      get { self != nil }
      set {
        guard !newValue else { return }
        self = nil
      }
    }

    fileprivate subscript(default defaultSubscript: DefaultSubscript<Wrapped>) -> Wrapped {
      get { self ?? defaultSubscript.value }
      set {
        defaultSubscript.value = newValue
        if self != nil { self = newValue }
      }
    }
  }

  private final class DefaultSubscript<Value>: Hashable {
    var value: Value
    init(_ value: Value) {
      self.value = value
    }
    static func == (lhs: DefaultSubscript, rhs: DefaultSubscript) -> Bool {
      lhs === rhs
    }
    func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(self))
    }
  }

  extension CasePathable {
    fileprivate subscript<Member>(
      keyPath: KeyPath<Self.AllCasePaths, AnyCasePath<Self, Member>>
    ) -> Member? {
      get { Self.allCasePaths[keyPath: keyPath].extract(from: self) }
      set {
        guard let newValue else { return }
        self = Self.allCasePaths[keyPath: keyPath].embed(newValue)
      }
    }
  }

  extension Optional where Wrapped: CasePathable {
    fileprivate subscript<Member>(
      keyPath: KeyPath<Wrapped.AllCasePaths, AnyCasePath<Wrapped, Member>>
    ) -> Member? {
      get {
        guard let wrapped = self else { return nil }
        return Wrapped.allCasePaths[keyPath: keyPath].extract(from: wrapped)
      }
      set {
        guard let newValue else {
          self = nil
          return
        }
        self = Wrapped.allCasePaths[keyPath: keyPath].embed(newValue)
      }
    }
  }
#endif  // canImport(SwiftUI)
