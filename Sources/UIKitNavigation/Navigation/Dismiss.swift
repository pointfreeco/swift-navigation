#if canImport(UIKit)
  import UIKit
  @_spi(RuntimeWarn) import SwiftUINavigationCore

  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  @MainActor
  public struct UIDismissAction: Sendable {
    let run: @MainActor @Sendable (UITransaction) -> Void

    // TODO: Should there be a `public init`? Is it useful to create this outside the library?

    public func callAsFunction() {
      run(.current)
    }
  }

  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  private enum DismissActionTrait: UITraitDefinition {
    static let defaultValue = UIDismissAction { _ in
      runtimeWarn(
        """
        A view controller requested dismissal, but couldn't be dismissed.
        """
      )
    }
  }

  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  extension UITraitCollection {
    public var dismiss: UIDismissAction { self[DismissActionTrait.self] }

    // TODO: `isPresented`?
  }

  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  extension UIMutableTraits {
    var dismiss: UIDismissAction {
      get { self[DismissActionTrait.self] }
      set { self[DismissActionTrait.self] = newValue }
    }
  }
#endif
