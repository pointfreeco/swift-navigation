#if canImport(UIKit)
  import UIKit
  @_spi(RuntimeWarn) import SwiftUINavigationCore

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @MainActor
  public struct UIDismissAction: Sendable {
    let run: (@MainActor @Sendable (UITransaction) -> Void)?

    public func callAsFunction() {
      guard let run else {
        runtimeWarn(
          """
          A view controller requested dismissal, but couldn't be dismissed.
          """
        )
        return
      }
      run(.current)
    }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  private enum DismissActionTrait: UITraitDefinition {
    static let defaultValue = UIDismissAction(run: nil)
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension UITraitCollection {
    public var dismiss: UIDismissAction { self[DismissActionTrait.self] }
    public var isPresented: Bool { dismiss.run != nil }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension UIMutableTraits {
    var dismiss: UIDismissAction {
      get { self[DismissActionTrait.self] }
      set { self[DismissActionTrait.self] = newValue }
    }
  }
#endif
