#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import SwiftNavigation

  #if canImport(SwiftUI)
    import SwiftUI
  #endif

  /// Executes a closure with the specified animation and returns the result.
  ///
  /// - Parameters:
  ///   - animation: An animation, set in the ``SwiftNavigation/UITransaction/appKit`` property of
  ///     the thread's current transaction.
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
      case let .appKit(animation):
        var result: Swift.Result<Result, Error>?
        NSAnimationContext.runAnimationGroup { context in
          context.allowsImplicitAnimation = true
          context.duration = animation.duration
          context.timingFunction = animation.timingFunction
          result = Swift.Result(catching: body)
        } completionHandler: {
          completion?(true)
        }
        return try result!._rethrowGet()

      case let .swiftUI(animation):
        var result: Swift.Result<Result, Error>?
        #if swift(>=6)
          if #available(macOS 15, *) {
            NSAnimationContext.animate(animation) {
              result = Swift.Result(catching: body)
            } completion: {
              completion?(true)
            }
            return try result!._rethrowGet()
          }
        #endif
        _ = animation
        fatalError()
      }
    }

    fileprivate enum Framework: Hashable, Sendable {
      case appKit(AppKit)
      case swiftUI(Animation)

      fileprivate struct AppKit: Hashable, @unchecked Sendable {
        fileprivate var duration: TimeInterval
        fileprivate var timingFunction: CAMediaTimingFunction?

        func hash(into hasher: inout Hasher) {
          hasher.combine(duration)
        }
      }
    }
  }

  extension AppKitAnimation {
    /// Animates changes with the specified duration and timing function.
    ///
    /// A value description of `UIView.runAnimationGroup` that can be used with
    /// ``withAppKitAnimation(_:_:completion:)``.
    ///
    /// - Parameters:
    ///   - duration: The length of time, expressed in seconds, that the animation takes to
    ///     complete.
    ///   - timingFunction: The timing function used for the animation.
    /// - Returns: An animation with the specified duration and timing function.
    public static func animate(
      duration: TimeInterval = 0.25,
      timingFunction: CAMediaTimingFunction? = nil
    ) -> Self {
      Self(
        framework: .appKit(
          Framework.AppKit(
            duration: duration,
            timingFunction: timingFunction
          )
        )
      )
    }

    /// Animates changes using the specified SwiftUI animation.
    ///
    /// - Parameter animation: The animation to use for the changes.
    @available(macOS 15, *)
    public init(_ animation: Animation) {
      self.init(framework: .swiftUI(animation))
    }

    /// A default animation instance.
    public static var `default`: Self {
      .animate()
    }

    /// An animation that moves at a constant speed.
    ///
    /// - Returns: A linear animation with the default duration.
    public static var linear: Self { .linear(duration: 0.25) }

    /// An animation that moves at a constant speed during a specified duration.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: A linear animation with a specified duration.
    public static func linear(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .linear))
    }

    /// An animation that starts slowly and then increases speed towards the end of the movement.
    ///
    /// - Returns: An ease-in animation with the default duration.
    public static var easeIn: Self { .easeIn(duration: 0.25) }

    /// An animation with a specified duration that starts slowly and then increases speed towards
    /// the end of the movement.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: An ease-in animation with a specified duration.
    public static func easeIn(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .easeIn))
    }

    /// An animation that starts quickly and then slows towards the end of the movement.
    ///
    /// - Returns: An ease-out animation with the default duration.
    public static var easeOut: Self { .easeOut(duration: 0.25) }

    /// An animation with a specified duration that starts quickly and then slows towards the end of
    /// the movement.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: An ease-out animation with a specified duration.
    public static func easeOut(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .easeOut))
    }

    /// An animation that combines the behaviors of in and out easing animations.
    ///
    /// - Returns: An ease-in ease-out animation with the default duration.
    public static var easeInOut: Self { .easeInOut(duration: 0.25) }

    /// An animation with a specified duration that combines the behaviors of in and out easing
    /// animations.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: An ease-in ease-out animation with a specified duration.
    public static func easeInOut(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .easeInEaseOut))
    }
  }
#endif
