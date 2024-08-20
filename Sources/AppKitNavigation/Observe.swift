#if canImport(AppKit) && !targetEnvironment(macCatalyst)
@_spi(Internals) import SwiftNavigation
import AppKit

@MainActor
extension NSObject {
    @discardableResult
    public func observe(_ apply: @escaping @MainActor @Sendable () -> Void) -> ObservationToken {
        observe { _ in apply() }
    }

    @discardableResult
    public func observe(
        _ apply: @escaping @MainActor @Sendable (_ transaction: UITransaction) -> Void
    ) -> ObservationToken {
        let token = SwiftNavigation.observe { transaction in
            MainActor._assumeIsolated {
                withUITransaction(transaction) {
                    if transaction.appKit.disablesAnimations {
                        NSView.performWithoutAnimation { apply(transaction) }
                        for completion in transaction.appKit.animationCompletions {
                            completion(true)
                        }
                    } else if let animation = transaction.appKit.animation {
                        return animation.perform(
                            { apply(transaction) },
                            completion: transaction.appKit.animationCompletions.isEmpty
                                ? nil
                                : {
                                    for completion in transaction.appKit.animationCompletions {
                                        completion($0)
                                    }
                                }
                        )
                    } else {
                        apply(transaction)
                        for completion in transaction.appKit.animationCompletions {
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

    fileprivate var tokens: [Any] {
        get {
            objc_getAssociatedObject(self, Self.tokensKey) as? [Any] ?? []
        }
        set {
            objc_setAssociatedObject(self, Self.tokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private static let tokensKey = malloc(1)!
}

extension NSView {
    fileprivate static func performWithoutAnimation(_ block: () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = false
            block()
        }
    }
}

#endif
