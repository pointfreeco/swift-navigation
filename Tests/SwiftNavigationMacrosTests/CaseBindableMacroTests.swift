// NB: These snapshots pin the CasePaths 2.x expansion. The CasePaths 1.x configuration
//     delegates to that version's 'CasePathableMacro', whose output these snapshots do not
//     describe.
#if CasePaths && canImport(MacroTesting) && canImport(CasePaths2)
  import CasePathsMacrosSupport
  import MacroTesting
  import SnapshotTesting
  import SwiftNavigationMacros
  import SwiftSyntaxBuilder
  import SwiftSyntaxMacroExpansion
  import Testing

  @Suite(
    .macros(
      [
        "CaseBindable": MacroSpec(
          type: CaseBindableMacro.self,
          conformances: ["CasePathable", "CaseBindable"]
        ),
        "CasePathable": MacroSpec(
          type: CasePathableMacro.self,
          conformances: ["CasePathable"]
        ),
      ],
      record: .failed
    )
  )
  struct CaseBindableMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @CaseBindable
        enum Status {
          case inStock(quantity: Int)
          case outOfStock(isOnBackOrder: Bool)
          case onSale(price: Int, discount: Int)
          case discontinued
        }
        """
      } expansion: {
        #"""
        enum Status {
          case inStock(quantity: Int)
          case outOfStock(isOnBackOrder: Bool)
          case onSale(price: Int, discount: Int)
          case discontinued

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Status) -> Status {
              value
            }
            public func extract(from root: Status) -> Status? {
              root
            }
            public subscript(root: Status) -> CasePaths.PartialCaseKeyPath<Status> {
              if case .inStock = root {
                return \.inStock
              }
              if case .outOfStock = root {
                return \.outOfStock
              }
              if case .onSale = root {
                return \.onSale
              }
              if case .discontinued = root {
                return \.discontinued
              }
              return \.never
            }
            public struct _$inStock: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Status {
                Status.inStock(quantity: value)
              }
              public func extract(from root: Status) -> Int? {
                guard case let .inStock(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var inStock: _$inStock {
              _$inStock()
            }
            public struct _$outOfStock: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Bool) -> Status {
                Status.outOfStock(isOnBackOrder: value)
              }
              public func extract(from root: Status) -> Bool? {
                guard case let .outOfStock(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var outOfStock: _$outOfStock {
              _$outOfStock()
            }
            public struct _$onSale: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (price: Int, discount: Int)) -> Status {
                Status.onSale(price: value.0, discount: value.1)
              }
              public func extract(from root: Status) -> (price: Int, discount: Int)? {
                guard case let .onSale(v0, v1) = root else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public var onSale: _$onSale {
              _$onSale()
            }
            public struct _$discontinued: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Status {
                Status.discontinued
              }
              public func extract(from root: Status) -> Void? {
                guard case .discontinued = root else {
                  return nil
                }
                return ()
              }
            }
            public var discontinued: _$discontinued {
              _$discontinued()
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Status>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Status>] = []
              allCasePaths.append(\.inStock)
              allCasePaths.append(\.outOfStock)
              allCasePaths.append(\.onSale)
              allCasePaths.append(\.discontinued)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Status>
          ) -> Swift.String? {
            if keyPath == \.inStock {
              return "inStock"
            }
            if keyPath == \.outOfStock {
              return "outOfStock"
            }
            if keyPath == \.onSale {
              return "onSale"
            }
            if keyPath == \.discontinued {
              return "discontinued"
            }
            return nil
          }

          public enum UIBindingEnumeration {
            case inStock(SwiftNavigation.UIBinding<Int>)
            case outOfStock(SwiftNavigation.UIBinding<Bool>)
            case onSale(SwiftNavigation.UIBinding<(price: Int, discount: Int)>)
            case discontinued
          }

          public static func _$caseBinding(
            _ binding: SwiftNavigation.UIBinding<Self>
          ) -> UIBindingEnumeration {
            switch binding.wrappedValue {
            case .inStock:
              return .inStock(binding._$case(\.inStock))
            case .outOfStock:
              return .outOfStock(binding._$case(\.outOfStock))
            case .onSale:
              return .onSale(binding._$case(\.onSale))
            case .discontinued:
              return .discontinued
            }
          }

          #if canImport(SwiftUI)
          public enum BindingEnumeration {
            case inStock(SwiftNavigation._Binding<Int>)
            case outOfStock(SwiftNavigation._Binding<Bool>)
            case onSale(SwiftNavigation._Binding<(price: Int, discount: Int)>)
            case discontinued
          }
          public static func _$caseBinding(
            _ binding: SwiftNavigation._Binding<Self>
          ) -> BindingEnumeration {
            switch binding._$wrappedValue {
            case .inStock:
              return .inStock(binding._$case(\.inStock))
            case .outOfStock:
              return .outOfStock(binding._$case(\.outOfStock))
            case .onSale:
              return .onSale(binding._$case(\.onSale))
            case .discontinued:
              return .discontinued
            }
          }
          #endif
        }

        extension Status: nonisolated CasePathable, nonisolated CaseBindable {
        }
        """#
      }
    }

    @Test func casePathableOverlap() {
      assertMacro {
        """
        @CasePathable
        @CaseBindable
        enum Status {
          case inStock(quantity: Int)
          case discontinued
        }
        """
      } expansion: {
        #"""
        enum Status {
          case inStock(quantity: Int)
          case discontinued

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Status) -> Status {
              value
            }
            public func extract(from root: Status) -> Status? {
              root
            }
            public subscript(root: Status) -> CasePaths.PartialCaseKeyPath<Status> {
              if case .inStock = root {
                return \.inStock
              }
              if case .discontinued = root {
                return \.discontinued
              }
              return \.never
            }
            public struct _$inStock: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Status {
                Status.inStock(quantity: value)
              }
              public func extract(from root: Status) -> Int? {
                guard case let .inStock(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var inStock: _$inStock {
              _$inStock()
            }
            public struct _$discontinued: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Status {
                Status.discontinued
              }
              public func extract(from root: Status) -> Void? {
                guard case .discontinued = root else {
                  return nil
                }
                return ()
              }
            }
            public var discontinued: _$discontinued {
              _$discontinued()
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Status>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Status>] = []
              allCasePaths.append(\.inStock)
              allCasePaths.append(\.discontinued)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Status>
          ) -> Swift.String? {
            if keyPath == \.inStock {
              return "inStock"
            }
            if keyPath == \.discontinued {
              return "discontinued"
            }
            return nil
          }

          public enum UIBindingEnumeration {
            case inStock(SwiftNavigation.UIBinding<Int>)
            case discontinued
          }

          public static func _$caseBinding(
            _ binding: SwiftNavigation.UIBinding<Self>
          ) -> UIBindingEnumeration {
            switch binding.wrappedValue {
            case .inStock:
              return .inStock(binding._$case(\.inStock))
            case .discontinued:
              return .discontinued
            }
          }

          #if canImport(SwiftUI)
          public enum BindingEnumeration {
            case inStock(SwiftNavigation._Binding<Int>)
            case discontinued
          }
          public static func _$caseBinding(
            _ binding: SwiftNavigation._Binding<Self>
          ) -> BindingEnumeration {
            switch binding._$wrappedValue {
            case .inStock:
              return .inStock(binding._$case(\.inStock))
            case .discontinued:
              return .discontinued
            }
          }
          #endif
        }

        extension Status: nonisolated CasePathable {
        }

        extension Status: SwiftNavigation.CaseBindable {
        }
        """#
      }
    }
  }
#endif
