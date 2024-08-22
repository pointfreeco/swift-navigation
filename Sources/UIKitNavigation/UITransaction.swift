#if canImport(UIKit) && !os(watchOS)

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
      set {
        self[UIKitKey.self] = newValue
        self.perform = { transaction, work in
          MainActor._assumeIsolated {
#if os(watchOS)
            //apply(transaction)
#else
            if transaction.uiKit.disablesAnimations {
              UIView.performWithoutAnimation { work() }
              for completion in transaction.uiKit.animationCompletions {
                completion(true)
              }
            } else if let animation = transaction.uiKit.animation {
              return animation.perform(
                { work() },
                completion: transaction.uiKit.animationCompletions.isEmpty
                ? nil
                : {
                  for completion in transaction.uiKit.animationCompletions {
                    completion($0)
                  }
                }
              )
            } else {
              work()
              for completion in transaction.uiKit.animationCompletions {
                completion(true)
              }
            }
#endif
          }
        }
      }
    }

    private enum UIKitKey: UITransactionKey {
      static let defaultValue = UIKit()
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
