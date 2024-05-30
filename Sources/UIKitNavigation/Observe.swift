#if canImport(UIKit)
  import UIKit

  extension NSObject {
    @discardableResult
    @MainActor
    public func observe(
      _ apply: @escaping @MainActor @Sendable (UITransaction) -> Void
    ) -> ObservationToken {
      let token = SwiftNavigation.observe { transaction in
        MainActor.assumeIsolated {
          withUITransaction(transaction) {
            if transaction.disablesAnimations {
              UIView.performWithoutAnimation { apply(transaction) }
              for completion in transaction.animationCompletions {
                completion(true)
              }
            } else if let animation = transaction.animation {
              return animation.perform(
                { apply(transaction) },
                completion: transaction.animationCompletions.isEmpty
                  ? nil
                  : {
                    for completion in transaction.animationCompletions {
                      completion($0)
                    }
                  }
              )
            } else {
              apply(transaction)
              for completion in transaction.animationCompletions {
                completion(true)
              }
            }
          }
        }
      } task: { transaction, work in
        DispatchQueue.main.async {
          withUITransaction(transaction, work)
        }
      }
      tokens.append(token)
      return token
    }

    @discardableResult
    @MainActor
    public func observe(_ apply: @escaping @MainActor @Sendable () -> Void) -> ObservationToken {
      observe { _ in apply() }
    }

    fileprivate var tokens: [Any] {
      get {
        objc_getAssociatedObject(self, tokensKey) as? [Any] ?? []
      }
      set {
        objc_setAssociatedObject(self, tokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }

  private let tokensKey = malloc(1)!
#endif
