#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

#if canImport(SwiftUI)
import SwiftUI
#endif

import SwiftNavigation

/// Executes a closure with the specified animation and returns the result.
///
/// - Parameters:
///   - animation: An animation, set in the ``UITransaction/appKit`` property of the thread's
///     current transaction.
///   - body: A closure to execute.
///   - completion: A completion to run when the animation is complete.
/// - Returns: The result of executing the closure with the specified animation.
@MainActor
public func withAppKitAnimation<Result>(
    _ animation: AppKitAnimation? = .default,
    _ body: () throws -> Result,
    completion: (@Sendable (Bool?) -> Void)? = nil
) rethrows -> Result {
    var transaction = UITransaction()
    transaction.appKit.animation = animation
    if let completion {
        transaction.appKit.addAnimationCompletion(completion)
    }
    return try withUITransaction(transaction, body)
}

/// The way a view changes over time to create a smooth visual transition from one state to
/// another.
public struct AppKitAnimation: Hashable, Sendable {
    fileprivate let framework: Framework

    @MainActor
    func perform<Result>(
        _ body: () throws -> Result,
        completion: ((Bool?) -> Void)? = nil
    ) rethrows -> Result {
        switch framework {
        case let .swiftUI(animation):
            _ = animation
            fatalError()
        case let .appKit(animation):
            var result: Swift.Result<Result, Error>?
            NSAnimationContext.runAnimationGroup { context in
                context.duration = animation.duration
                result = Swift.Result(catching: body)
            } completionHandler: {
                completion?(true)
            }

            return try result!._rethrowGet()
        }
    }

    fileprivate enum Framework: Hashable, Sendable {
        case appKit(AppKit)
        case swiftUI(Animation)

        fileprivate struct AppKit: Hashable, Sendable {
            fileprivate var duration: TimeInterval

            func hash(into hasher: inout Hasher) {
                hasher.combine(duration)
            }
        }
    }
}

extension AppKitAnimation {
    /// Performs am animation using a timing curve corresponding to the motion of a physical spring.
    ///
    /// A value description of
    /// `UIView.animate(withDuration:delay:dampingRatio:velocity:options:animations:completion:)`
    /// that can be used with ``withAppKitAnimation(_:_:completion:)``.
    ///
    /// - Parameters:
    ///   - duration: The total duration of the animations, measured in seconds. If you specify a
    ///     negative value or `0`, the changes are made without animating them.
    /// - Returns: An animation using a timing curve corresponding to the motion of a physical
    ///   spring.
    public static func animate(
        withDuration duration: TimeInterval = 0.25
    ) -> Self {
        Self(
            framework: .appKit(
                Framework.AppKit(
                    duration: duration
                )
            )
        )
    }

    /// A default animation instance.
    public static var `default`: Self {
        return .animate()
    }
}
#endif
