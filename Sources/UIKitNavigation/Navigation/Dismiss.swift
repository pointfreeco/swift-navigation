#if canImport(UIKit) && !os(watchOS)
  import IssueReporting
  import UIKit

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @MainActor
  public struct UIDismissAction: Sendable {
    let run: (@MainActor @Sendable (UITransaction) -> Void)?

    public func callAsFunction() {
      guard let run else {
        reportIssue(
          """
          A view controller requested dismissal, but couldn't be dismissed.

          'UITraitCollection.dismiss()' must be called from an object that was presented using a \
          binding, for example 'UIViewController.present(item:)', and \
          'UIViewController.navigationDestination(item:)'.
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
