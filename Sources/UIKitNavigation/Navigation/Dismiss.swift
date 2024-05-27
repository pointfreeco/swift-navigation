import UIKit

@available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
@MainActor
public struct UIDismissAction: Sendable {
  let run: @MainActor @Sendable () -> Void

  // TODO: `public init`?

  public func callAsFunction() {
    run()
  }
}

@available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
private enum DismissActionTrait: UITraitDefinition {
  static let defaultValue = UIDismissAction { 
    // TODO: Runtime warn that there is no presentation context
  }
}

@available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
extension UITraitCollection {
  public var dismiss: UIDismissAction { self[DismissActionTrait.self] }
}

@available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
extension UIMutableTraits {
  var dismiss: UIDismissAction {
    get { self[DismissActionTrait.self] }
    set { self[DismissActionTrait.self] = newValue }
  }
}
