#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import SwiftNavigation

  extension UITransaction {
    public init(animation: AppKitAnimation? = nil) {
      self.init()
      appKit.animation = animation
    }

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
        }
      }
    }

    public struct AppKit: Sendable {
      public var animation: AppKitAnimation?

      public var disablesAnimations = false

      var animationCompletions: [@Sendable (Bool?) -> Void] = []

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
