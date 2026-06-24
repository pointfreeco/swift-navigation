#if CasePaths
  public import CasePaths

  /// Defines and implements conformance of the `CaseBindable` protocol.
  ///
  /// This macro adds binding support to an enumeration by conforming it to the ``CaseBindable``
  /// protocol. For example, the following code applies the `@CaseBindable` macro to the type
  /// `Item.Status`, making it possible to switch over bindings to each case of the enum:
  ///
  /// ```swift
  /// struct Item {
  ///   @CaseBindable enum Status {
  ///     case inStock(quantity: Int)
  ///     case outOfStock(isOnBackOrder: Bool)
  ///   }
  ///   var status: Status
  /// }
  /// // ...
  /// @Binding var item: Item
  /// // ...
  /// switch $item.status {
  /// case .inStock(let $quantity):
  ///   Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
  /// case .outOfStock(let $isOnBackOrder):
  ///   Toggle("Is on back order?", isOn: $isOnBackOrder)
  /// }
  /// ```
  @attached(extension, conformances: CasePathable, CasePathIterable, CaseBindable)
  @attached(
    member,
    names: named(AllCasePaths),
    named(allCasePaths),
    named(_$Element),
    named(UIBindingEnumeration),
    named(BindingEnumeration),
    named(_$caseBinding)
  )
  public macro CaseBindable() =
    #externalMacro(module: "SwiftNavigationMacros", type: "CaseBindableMacro")

  /// A type whose binding can be switched over exhaustively.
  ///
  /// Use the ``CaseBindable()`` macro to generate a conformance.
  public protocol CaseBindable: CasePathable {
    associatedtype UIBindingEnumeration

    static func _$caseBinding(_ binding: UIBinding<Self>) -> UIBindingEnumeration

    #if canImport(SwiftUI)
      associatedtype BindingEnumeration

      static func _$caseBinding(_ binding: SwiftUI.Binding<Self>) -> BindingEnumeration
    #endif
  }

  extension UIBinding where Value: CaseBindable {
    /// An enumeration of bindings that can be switched over exhaustively.
    ///
    /// ```swift
    /// @UIBinding var status: Status
    /// // ...
    /// switch $status.cases {
    /// case .inStock(let $quantity):
    ///   Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
    /// case .outOfStock(let $isOnBackOrder):
    ///   Toggle("Is on back order?", isOn: $isOnBackOrder)
    /// }
    /// ```
    public var cases: Value.UIBindingEnumeration {
      Value._$caseBinding(self)
    }
  }

  extension UIBinding {
    /// Derives an enumeration of bindings that can be switched over exhaustively _via_ dynamic
    /// member lookup.
    ///
    /// You don't call this subscript directly. Instead, Swift calls it for you when you access a
    /// property from the underlying `Value` directly on this binding:
    ///
    /// ```swift
    /// @UIBinding var item: Item
    /// // ...
    /// switch $item.status {
    /// case .inStock(let $quantity):
    ///   Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
    /// case .outOfStock(let $isOnBackOrder):
    ///   Toggle("Is on back order?", isOn: $isOnBackOrder)
    /// }
    /// ```
    public subscript<Member: CaseBindable>(
      dynamicMember keyPath: WritableKeyPath<Value, Member>
    ) -> Member.UIBindingEnumeration {
      let binding: UIBinding<Member> = self[dynamicMember: keyPath]
      return binding.cases
    }
  }

  extension UIBindable {
    /// Derives an enumeration of bindings that can be switched over exhaustively _via_ dynamic
    /// member lookup.
    ///
    /// You don't call this subscript directly. Instead, Swift calls it for you when you access a
    /// property from the underlying `Value` directly on this bindable object:
    ///
    /// ```swift
    /// @UIBindable var item: Item
    /// // ...
    /// switch $item.status {
    /// case .inStock(let $quantity):
    ///   Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
    /// case .outOfStock(let $isOnBackOrder):
    ///   Toggle("Is on back order?", isOn: $isOnBackOrder)
    /// }
    /// ```
    public subscript<Member: CaseBindable>(
      dynamicMember keyPath: ReferenceWritableKeyPath<Value, Member>
    ) -> Member.UIBindingEnumeration where Value: AnyObject {
      let binding: UIBinding<Member> = self[dynamicMember: keyPath]
      return binding.cases
    }
  }

  extension UIBinding where Value: CasePathable {
    public func _$case<Member>(
      _ keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
    ) -> UIBinding<Member> {
      self[dynamicMember: keyPath]!
    }
  }

  #if canImport(SwiftUI)
    public import SwiftUI

    public typealias _Binding<Value> = SwiftUI.Binding<Value>

    extension SwiftUI.Binding where Value: CaseBindable {
      /// An enumeration of bindings that can be switched over exhaustively.
      ///
      /// ```swift
      /// @Binding var status: Status
      /// // ...
      /// switch $status.cases {
      /// case .inStock(let $quantity):
      ///   Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
      /// case .outOfStock(let $isOnBackOrder):
      ///   Toggle("Is on back order?", isOn: $isOnBackOrder)
      /// }
      /// ```
      public var cases: Value.BindingEnumeration {
        Value._$caseBinding(self)
      }
    }

    extension SwiftUI.Binding {
      /// Derives an enumeration of bindings that can be switched over exhaustively _via_ dynamic
      /// member lookup.
      ///
      /// You don't call this subscript directly. Instead, Swift calls it for you when you access a
      /// property from the underlying `Value` directly on this binding:
      ///
      /// ```swift
      /// @Binding var item: Item
      /// // ...
      /// switch $item.status {
      /// case .inStock(let $quantity):
      ///   Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
      /// case .outOfStock(let $isOnBackOrder):
      ///   Toggle("Is on back order?", isOn: $isOnBackOrder)
      /// }
      /// ```
      public subscript<Member: CaseBindable>(
        dynamicMember keyPath: WritableKeyPath<Value, Member>
      ) -> Member.BindingEnumeration {
        let binding: SwiftUI.Binding<Member> = self[dynamicMember: keyPath]
        return binding.cases
      }
    }

    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    extension SwiftUI.Bindable {
      /// Derives an enumeration of bindings that can be switched over exhaustively _via_ dynamic
      /// member lookup.
      ///
      /// You don't call this subscript directly. Instead, Swift calls it for you when you access a
      /// property from the underlying `Value` directly on this bindable object:
      ///
      /// ```swift
      /// @Bindable var item: Item
      /// // ...
      /// switch $item.status {
      /// case .inStock(let $quantity):
      ///   Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
      /// case .outOfStock(let $isOnBackOrder):
      ///   Toggle("Is on back order?", isOn: $isOnBackOrder)
      /// }
      /// ```
      public subscript<Member: CaseBindable>(
        dynamicMember keyPath: ReferenceWritableKeyPath<Value, Member>
      ) -> Member.BindingEnumeration where Value: AnyObject {
        let binding: SwiftUI.Binding<Member> = self[dynamicMember: keyPath]
        return binding.cases
      }
    }

    extension SwiftUI.Binding {
      public var _$wrappedValue: Value { wrappedValue }
    }

    extension SwiftUI.Binding where Value: CasePathable {
      public func _$case<Member>(
        _ keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
      ) -> SwiftUI.Binding<Member> {
        SwiftUI.Binding<Member>(_unwrapping: self[_case: keyPath])!
      }
    }

    extension SwiftUI.Binding {
      fileprivate init?(_unwrapping base: SwiftUI.Binding<Value?>) {
        guard let value = base.wrappedValue else { return nil }
        self = base[_default: _CaseDefault(value)]
      }
    }

    extension CasePathable {
      fileprivate subscript<Member>(
        _case keyPath: KeyPath<AllCasePaths, AnyCasePath<Self, Member>>
      ) -> Member? {
        get { Self.allCasePaths[keyPath: keyPath].extract(from: self) }
        set {
          guard let newValue else { return }
          self = Self.allCasePaths[keyPath: keyPath].embed(newValue)
        }
      }
    }

    extension Optional {
      fileprivate subscript(_default defaultValue: _CaseDefault<Wrapped>) -> Wrapped {
        get {
          defaultValue.value = self ?? defaultValue.value
          return defaultValue.value
        }
        set {
          defaultValue.value = newValue
          if self != nil { self = newValue }
        }
      }
    }

    private final class _CaseDefault<Value>: Hashable {
      var value: Value
      init(_ value: Value) { self.value = value }
      static func == (lhs: _CaseDefault, rhs: _CaseDefault) -> Bool { lhs === rhs }
      func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    }
  #endif
#endif
