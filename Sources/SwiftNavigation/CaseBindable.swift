#if CasePaths
  public import CasePaths

  public protocol CaseBindable: CasePathable {
    associatedtype UIBindingEnumeration

    static func _$caseBinding(_ binding: UIBinding<Self>) -> UIBindingEnumeration

    #if canImport(SwiftUI)
      associatedtype BindingEnumeration

      static func _$caseBinding(_ binding: SwiftUI.Binding<Self>) -> BindingEnumeration
    #endif
  }

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

  extension UIBinding where Value: CaseBindable {
    public var cases: Value.UIBindingEnumeration {
      Value._$caseBinding(self)
    }
  }

  extension UIBinding {
    public subscript<Member: CaseBindable>(
      dynamicMember keyPath: WritableKeyPath<Value, Member>
    ) -> Member.UIBindingEnumeration {
      let binding: UIBinding<Member> = self[dynamicMember: keyPath]
      return binding.cases
    }
  }

  extension UIBindable {
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
      public var cases: Value.BindingEnumeration {
        Value._$caseBinding(self)
      }
    }

    extension SwiftUI.Binding {
      public subscript<Member: CaseBindable>(
        dynamicMember keyPath: WritableKeyPath<Value, Member>
      ) -> Member.BindingEnumeration {
        let binding: SwiftUI.Binding<Member> = self[dynamicMember: keyPath]
        return binding.cases
      }
    }

    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    extension SwiftUI.Bindable {
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
