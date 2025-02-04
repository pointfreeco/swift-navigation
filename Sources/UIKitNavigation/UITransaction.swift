#if canImport(UIKit) && !os(watchOS)
  import SwiftNavigation
  import UIKit

  extension UITransaction {
    /// Creates a transaction and assigns its animation property.
    ///
    /// - Parameter animation: The animation to perform when the current state changes.
    public init(animation: UIKitAnimation? = nil) {
      self.init()
      self.uiKit.animation = animation
    }

    /// UIKit-specific data associated with the current state change.
    public var uiKit: UIKit {
      get { self[UIKitKey.self] }
      set { self[UIKitKey.self] = newValue }
    }

    private enum UIKitKey: _UICustomTransactionKey {
      static let defaultValue = UIKit()

      static func perform(
        value: UIKit,
        operation: @Sendable () -> Void
      ) {
        MainActor._assumeIsolated {
          #if os(watchOS)
            operation()
          #else
            if value.disablesAnimations {
              UIView.performWithoutAnimation { operation() }
              for completion in value.animationCompletions {
                completion(true)
              }
            } else if let animation = value.animation {
              return animation.perform(
                { operation() },
                completion: value.animationCompletions.isEmpty
                  ? nil
                  : {
                    for completion in value.animationCompletions {
                      completion($0)
                    }
                  }
              )
            } else {
              operation()
              for completion in value.animationCompletions {
                completion(true)
              }
            }
          #endif
        }
      }
    }

    /// UIKit-specific data associated with a ``UITransaction``.
    public struct UIKit: Sendable {
      /// The animation, if any, associated with the current state change.
      public var animation: UIKitAnimation?

      /// A Boolean value that indicates whether views should disable animations.
      public var disablesAnimations = false

      var animationCompletions: [@Sendable (Bool?) -> Void] = []

      /// Adds a completion to run when the animations created with this transaction are all
      /// complete.
      ///
      /// The completion callback will always be fired exactly one time.
      public mutating func addAnimationCompletion(
        _ completion: @escaping @Sendable (Bool?) -> Void
      ) {
        animationCompletions.append(completion)
      }
    }
  }

  private enum AnimationCompletionsKey: UITransactionKey {
    static let defaultValue: [@Sendable (Bool?) -> Void] = []
  }

  private enum DisablesAnimationsKey: UITransactionKey {
    static let defaultValue = false
  }
#endif
