#if canImport(UIKit)
  import UIKit
  @_spi(RuntimeWarn) import SwiftUINavigationCore

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @MainActor
  public struct UIPushAction: Sendable {
    let run: (@MainActor @Sendable (AnyHashable) -> Void)?

    public func callAsFunction<Element: Hashable>(value: Element) {
      guard let run else {
        runtimeWarn(
          """
          Tried to push a value from outside of a navigation stack.

          'UITraitCollection.push(value:)' must be called from an object in a \
          'NavigationStackController'.
          """
        )
        return
      }
      run(value)
    }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  private enum PushActionTrait: UITraitDefinition {
    static let defaultValue = UIPushAction(run: nil)
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension UITraitCollection {
    public var push: UIPushAction { self[PushActionTrait.self] }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension UIMutableTraits {
    var push: UIPushAction {
      get { self[PushActionTrait.self] }
      set { self[PushActionTrait.self] = newValue }
    }
  }
#endif
