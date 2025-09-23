#if canImport(UIKit) && !os(watchOS)
  import UIKit

  #if canImport(SwiftUI)
    import SwiftUI
  #endif

  /// Executes a closure with the specified animation and returns the result.
  ///
  /// - Parameters:
  ///   - animation: An animation, set in the ``UITransaction/uiKit`` property of the thread's
  ///     current transaction.
  ///   - body: A closure to execute.
  ///   - completion: A completion to run when the animation is complete.
  /// - Returns: The result of executing the closure with the specified animation.
  @MainActor
  public func withUIKitAnimation<Result>(
    _ animation: UIKitAnimation? = .default,
    _ body: () throws -> Result,
    completion: (@Sendable (Bool?) -> Void)? = nil
  ) rethrows -> Result {
    var transaction = UITransaction()
    transaction.uiKit.animation = animation
    if let completion {
      transaction.uiKit.addAnimationCompletion(completion)
    }
    return try withUITransaction(transaction, body)
  }

  /// The way a view changes over time to create a smooth visual transition from one state to
  /// another.
  public struct UIKitAnimation: Hashable, Sendable {
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
              animation,
              changes: { result = Swift.Result(catching: body) },
              completion: completion.map { completion in { completion(true) } }
            )
            return try result!._rethrowGet()
          }
        #endif
        _ = animation
        fatalError()

      case let .uiKit(animation):
        func animations() throws -> Result {
          guard let repeatModifier = animation.repeatModifier else { return try body() }
          var result: Swift.Result<Result, Error>?
          UIView.modifyAnimations(
            withRepeatCount: repeatModifier.count,
            autoreverses: repeatModifier.autoreverses
          ) {
            result = Swift.Result(catching: body)
          }
          return try result!._rethrowGet()
        }

        switch animation.style {
        case .iOS4:
          var result: Swift.Result<Result, Error>?
          withoutActuallyEscaping(animations) { animations in
            UIView.animate(
              withDuration: animation.duration * animation.speed,
              delay: animation.delay * animation.speed,
              options: animation.options,
              animations: { result = Swift.Result(catching: animations) },
              completion: completion
            )
          }
          return try result!._rethrowGet()

        case let .iOS7(dampingRatio, velocity):
          var result: Swift.Result<Result, Error>?
          withoutActuallyEscaping(animations) { animations in
            UIView.animate(
              withDuration: animation.duration * animation.speed,
              delay: animation.delay * animation.speed,
              usingSpringWithDamping: dampingRatio,
              initialSpringVelocity: velocity,
              options: animation.options,
              animations: { result = Swift.Result(catching: animations) },
              completion: completion
            )
          }
          return try result!._rethrowGet()

        case let .iOS17(bounce, initialSpringVelocity):
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            var result: Swift.Result<Result, Error>?
            UIView.animate(
              springDuration: animation.duration * animation.speed,
              bounce: bounce,
              initialSpringVelocity: initialSpringVelocity,
              delay: animation.delay * animation.speed,
              options: animation.options,
              animations: { result = Swift.Result(catching: animations) },
              completion: completion
            )
            return try result!._rethrowGet()
          } else {
            fatalError()
          }
        }
      }
    }

    fileprivate enum Framework: Hashable, Sendable {
      case uiKit(UIKit)
      case swiftUI(Animation)

      fileprivate struct UIKit: Hashable, Sendable {
        fileprivate var delay: TimeInterval
        fileprivate var duration: TimeInterval
        fileprivate var options: UIView.AnimationOptions
        fileprivate var repeatModifier: RepeatModifier?
        fileprivate var speed: Double = 1
        fileprivate var style: Style

        func hash(into hasher: inout Hasher) {
          hasher.combine(delay)
          hasher.combine(duration)
          hasher.combine(options.rawValue)
          hasher.combine(repeatModifier)
          hasher.combine(speed)
          hasher.combine(style)
        }

        fileprivate struct RepeatModifier: Hashable, Sendable {
          var autoreverses = true
          var count: CGFloat = 1
        }

        fileprivate enum Style: Hashable, Sendable {
          case iOS4
          case iOS7(dampingRatio: CGFloat, velocity: CGFloat)
          case iOS17(bounce: CGFloat = 0, initialSpringVelocity: CGFloat = 0)
        }
      }
    }

    /// Delays the start of the animation by the specified number of seconds.
    ///
    /// - Parameter delay: The number of seconds to delay the start of the animation.
    /// - Returns: An animation with a delayed start.
    public func delay(_ delay: TimeInterval) -> Self {
      switch framework {
      case let .swiftUI(animation):
        return UIKitAnimation(framework: .swiftUI(animation.delay(delay)))
      case var .uiKit(animation):
        animation.delay += delay
        return UIKitAnimation(framework: .uiKit(animation))
      }
    }

    /// Repeats the animation for a specific number of times.
    ///
    /// - Parameters:
    ///   - repeatCount: The number of times that the animation repeats. Each repeated sequence
    ///     starts at the beginning when `autoreverse` is `false`.
    ///   - autoreverses: A Boolean value that indicates whether the animation sequence plays in
    ///     reverse after playing forward. Autoreverse counts towards the `repeatCount`. For
    ///     instance, a `repeatCount` of one plays the animation forward once, but it doesn't play
    ///     in reverse even if `autoreverse` is `true`. When `autoreverse` is `true` and
    ///     `repeatCount` is `2`, the animation moves forward, then reverses, then stops.
    /// - Returns: An animation that repeats for specific number of times.
    public func repeatCount(_ repeatCount: Int, autoreverses: Bool = true) -> Self {
      switch framework {
      case let .swiftUI(animation):
        return UIKitAnimation(
          framework: .swiftUI(animation.repeatCount(repeatCount, autoreverses: autoreverses))
        )
      case var .uiKit(animation):
        animation.repeatModifier = Framework.UIKit.RepeatModifier(
          autoreverses: autoreverses,
          count: CGFloat(repeatCount)
        )
        return UIKitAnimation(framework: .uiKit(animation))
      }
    }

    /// Repeats the animation for the lifespan of the view containing the animation.
    ///
    /// - Parameter autoreverses: A Boolean value that indicates whether the animation sequence
    ///   plays in reverse after playing forward.
    /// - Returns: An animation that continuously repeats.
    public func repeatForever(autoreverses: Bool = true) -> Self {
      switch framework {
      case let .swiftUI(animation):
        return UIKitAnimation(
          framework: .swiftUI(animation.repeatForever(autoreverses: autoreverses))
        )
      case var .uiKit(animation):
        animation.repeatModifier = Framework.UIKit.RepeatModifier(
          autoreverses: autoreverses,
          count: .infinity
        )
        return UIKitAnimation(framework: .uiKit(animation))
      }
    }

    /// Changes the duration of an animation by adjusting its speed.
    ///
    /// - Parameter speed: The speed at which SwiftUI performs the animation.
    /// - Returns: An animation with the adjusted speed.
    public func speed(_ speed: Double) -> Self {
      switch framework {
      case let .swiftUI(animation):
        return UIKitAnimation(
          framework: .swiftUI(animation.speed(speed))
        )
      case var .uiKit(animation):
        animation.speed = speed
        return UIKitAnimation(framework: .uiKit(animation))
      }
    }
  }

  extension UIKitAnimation {
    /// Animate changes using the specified duration, delay, and options.
    ///
    /// A value description of `UIView.animate(withDuration:delay:options:animations:completion:)`
    /// that can be used with ``withUIKitAnimation(_:_:completion:)``.
    ///
    /// - Parameters:
    ///   - duration: The total duration of the animations, measured in seconds. If you specify a
    ///     negative value or `0`, the changes are made without animating them.
    ///   - delay: The amount of time (measured in seconds) to wait before beginning the animations.
    ///     Specify a value of `0` to begin the animations immediately.
    ///   - options: A mask of options indicating how you want to perform the animations. For a list
    ///     of valid constants, see `UIView.AnimationOptions`.
    /// - Returns: An animation with the specified duration, delay, and options.
    public static func animate(
      withDuration duration: TimeInterval,
      delay: CGFloat = 0,
      options: UIView.AnimationOptions = []
    ) -> Self {
      Self(
        framework: .uiKit(
          Framework.UIKit(delay: delay, duration: duration, options: options, style: .iOS4)
        )
      )
    }

    /// Performs am animation using a timing curve corresponding to the motion of a physical spring.
    ///
    /// A value description of
    /// `UIView.animate(withDuration:delay:dampingRatio:velocity:options:animations:completion:)`
    /// that can be used with ``withUIKitAnimation(_:_:completion:)``.
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
      withDuration duration: TimeInterval,
      delay: CGFloat = 0,
      usingSpringWithDamping dampingRatio: CGFloat,
      initialSpringVelocity velocity: CGFloat,
      options: UIView.AnimationOptions = []
    ) -> Self {
      Self(
        framework: .uiKit(
          Framework.UIKit(
            delay: delay,
            duration: duration,
            options: options,
            style: .iOS7(
              dampingRatio: dampingRatio,
              velocity: velocity
            )
          )
        )
      )
    }

    /// Animates changes using a spring animation with the specified duration, bounce, initial
    /// velocity, delay, and options.
    ///
    /// A value description of
    /// `UIView.animate(springDuration:bounce:initialSpringVelocity:delay:options:animations:completion:)`
    /// that can be used with ``withUIKitAnimation(_:_:completion:)``.
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    public static func animate(
      springDuration duration: TimeInterval = 0.5,
      bounce: CGFloat = 0,
      initialSpringVelocity: CGFloat = 0,
      delay: TimeInterval = 0,
      options: UIView.AnimationOptions = []
    ) -> Self {
      Self(
        framework: .uiKit(
          Framework.UIKit(
            delay: delay,
            duration: duration,
            options: options,
            style: .iOS17(
              bounce: bounce,
              initialSpringVelocity: initialSpringVelocity
            )
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

    /// An animation that moves at a constant speed.
    ///
    /// - Returns: A linear animation with the default duration.
    public static var linear: Self { .linear(duration: 0.35) }

    /// An animation that moves at a constant speed during a specified duration.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: A linear animation with a specified duration.
    public static func linear(duration: TimeInterval) -> Self {
      .animate(withDuration: duration, options: .curveLinear)
    }

    /// An animation that starts slowly and then increases speed towards the end of the movement.
    ///
    /// - Returns: An ease-in animation with the default duration.
    public static var easeIn: Self { .easeIn(duration: 0.35) }

    /// An animation with a specified duration that starts slowly and then increases speed towards
    /// the end of the movement.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: An ease-in animation with a specified duration.
    public static func easeIn(duration: TimeInterval) -> Self {
      .animate(withDuration: duration, options: .curveEaseIn)
    }

    /// An animation that starts quickly and then slows towards the end of the movement.
    ///
    /// - Returns: An ease-out animation with the default duration.
    public static var easeOut: Self { .easeOut(duration: 0.35) }

    /// An animation with a specified duration that starts quickly and then slows towards the end of
    /// the movement.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: An ease-out animation with a specified duration.
    public static func easeOut(duration: TimeInterval) -> Self {
      .animate(withDuration: duration, options: .curveEaseOut)
    }

    /// An animation that combines the behaviors of in and out easing animations.
    ///
    /// - Returns: An ease-in ease-out animation with the default duration.
    public static var easeInOut: Self { .easeInOut(duration: 0.35) }

    /// An animation with a specified duration that combines the behaviors of in and out easing
    /// animations.
    ///
    /// - Parameter duration: The length of time, expressed in seconds, that the animation takes to
    ///   complete.
    /// - Returns: An ease-in ease-out animation with a specified duration.
    public static func easeInOut(duration: TimeInterval) -> Self {
      .animate(withDuration: duration, options: .curveEaseInOut)
    }
  }
#endif
