#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  public import SwiftNavigation

  extension UITransaction {
    /// Creates a transaction and assigns its animation property.
    ///
    /// - Parameter animation: The animation to perform when the current state changes.
    public init(animation: AppKitAnimation? = nil) {
      self.init()
      appKit.animation = animation
    }

    /// AppKit-specific data associated with the current state change.
    public var appKit: AppKit {
      get { self[AppKitKey.self] }
      set { self[AppKitKey.self] = newValue }
    }

    private enum AppKitKey: _UICustomTransactionKey {
      static let defaultValue = AppKit()

      static func perform(
        value: AppKit,
        operation: @Sendable () -> Void
      ) {
        MainActor._assumeIsolated {
          if value.disablesAnimations {
            NSAnimationContext.runAnimationGroup { context in
              context.allowsImplicitAnimation = false
              operation()
            }
            for completion in value.animationCompletions {
              completion(true)
            }
          } else if let animation = value.animation {
            // NB: Spelled out with 'if' rather than a ternary: Swift 6.4 fails to type-check a
            //     ternary whose branch is a closure of optional '@Sendable' function type ("failed
            //     to produce diagnostic for expression").
            let completions = value.animationCompletions
            let completion: (@Sendable (Bool?) -> Void)?
            if completions.isEmpty {
              completion = nil
            } else {
              completion = { isFinished in
                for completion in completions {
                  completion(isFinished)
                }
              }
            }
            return animation.perform({ operation() }, completion: completion)
          } else {
            operation()
            for completion in value.animationCompletions {
              completion(true)
            }
          }
        }
      }
    }

    /// AppKit-specific data associated with a ``SwiftNavigation/UITransaction``.
    public struct AppKit: Sendable {
      /// The animation, if any, associated with the current state change.
      public var animation: AppKitAnimation?

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
