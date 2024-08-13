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
        #if swift(>=6)
          if #available(iOS 18, macOS 15, tvOS 18, visionOS 2, watchOS 11, *) {
            var result: Swift.Result<Result, Error>?
            UIView.animate(
              with: animation,
              changes: { result = Swift.Result(catching: body) },
              completion: completion.map { completion in { completion(true) } }
            )
            return try result!._rethrowGet()
          }
        #endif
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
    ///   - delay: The amount of time (measured in seconds) to wait before beginning the animations.
    ///     Specify a value of `0` to begin the animations immediately.
    ///   - dampingRatio: The damping ratio for the spring animation as it approaches its quiescent
    ///     state.
    ///
    ///     To smoothly decelerate the animation without oscillation, use a value of `1`. Employ a
    ///     damping ratio closer to zero to increase oscillation.
    ///   - velocity: The initial spring velocity. For smooth start to the animation, match this
    ///     value to the view's velocity as it was prior to attachment.
    ///
    ///     A value of `1` corresponds to the total animation distance traversed in one second. For
    ///     example, if the total animation distance is 200 points and you want the start of the
    ///     animation to match a view velocity of 100 pt/s, use a value of `0.5`.
    ///   - options: A mask of options indicating how you want to perform the animations. For a list
    ///     of valid constants, see `UIView.AnimationOptions`.
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


    /// Animates changes using the specified SwiftUI animation.
    ///
    /// - Parameter animation: The animation to use for the changes.
    @available(iOS 18, macOS 15, tvOS 18, visionOS 2, watchOS 11, *)
    public init(_ animation: Animation) {
      self.init(framework: .swiftUI(animation))
    }

    /// A default animation instance.
    public static var `default`: Self {
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
        return .animate()
      } else {
        return .animate(withDuration: 0.35)
      }
    }
  }
#endif
