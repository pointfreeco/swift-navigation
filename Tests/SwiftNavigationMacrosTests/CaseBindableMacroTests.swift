#if CasePaths && canImport(MacroTesting)
  import CasePathsMacrosSupport
  import MacroTesting
  import SnapshotTesting
  import SwiftNavigationMacros
  import Testing

  @Suite(
    .macros(
      [
        CaseBindableMacro.self,
        CasePathableMacro.self,
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

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Status) -> CasePaths.PartialCaseKeyPath<Status> {
              if root.is(\.inStock) {
                return \.inStock
              }
              if root.is(\.outOfStock) {
                return \.outOfStock
              }
              if root.is(\.onSale) {
                return \.onSale
              }
              if root.is(\.discontinued) {
                return \.discontinued
              }
              return \.never
            }
            public var inStock: CasePaths.AnyCasePath<Status, Int> {
              ._$embed(Status.inStock) {
                guard case let .inStock(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var outOfStock: CasePaths.AnyCasePath<Status, Bool> {
              ._$embed(Status.outOfStock) {
                guard case let .outOfStock(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var onSale: CasePaths.AnyCasePath<Status, (price: Int, discount: Int)> {
              ._$embed(Status.onSale) {
                guard case let .onSale(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public var discontinued: CasePaths.AnyCasePath<Status, Void> {
              ._$embed({
                  Status.discontinued
                }) {
                guard case .discontinued = $0 else {
                  return nil
                }
                return ()
              }
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

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
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

        extension Status: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }

        extension Status: SwiftNavigation.CaseBindable {
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

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Status) -> CasePaths.PartialCaseKeyPath<Status> {
              if root.is(\.inStock) {
                return \.inStock
              }
              if root.is(\.discontinued) {
                return \.discontinued
              }
              return \.never
            }
            public var inStock: CasePaths.AnyCasePath<Status, Int> {
              ._$embed(Status.inStock) {
                guard case let .inStock(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var discontinued: CasePaths.AnyCasePath<Status, Void> {
              ._$embed({
                  Status.discontinued
                }) {
                guard case .discontinued = $0 else {
                  return nil
                }
                return ()
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Status>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Status>] = []
              allCasePaths.append(\.inStock)
              allCasePaths.append(\.discontinued)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
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

        extension Status: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }

        extension Status: SwiftNavigation.CaseBindable {
        }
        """#
      }
    }
  }
#endif
