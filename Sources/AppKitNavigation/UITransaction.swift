#if canImport(AppKit) && !targetEnvironment(macCatalyst)

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

    private enum AppKitKey: UITransactionKey {
        static let defaultValue = AppKit()
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
