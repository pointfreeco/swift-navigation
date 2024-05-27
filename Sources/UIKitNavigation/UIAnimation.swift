import SwiftUI
import UIKit

// TODO: Support arbitrary body closures, `CASpringAnimation`?
// TODO: Should this be `UIKitAnimation`? `UIView.Animation`?

/// Executes a closure with the specified animation and returns the result.
///
/// - Parameters:
///   - animation: An animation, set as the the ``UITransaction/animation`` property of the thread's
///     current ``UITransaction``.
///   - body: A closure to execute.
///   - completion: A completion to run when the animation is complete.
/// - Returns: The result of executing the closure with the specified animation.
@MainActor
public func withUIAnimation<Result>(
  _ animation: UIAnimation? = .default,
  _ body: () throws -> Result,
  completion: (@Sendable (Bool) -> Void)? = nil
) rethrows -> Result {
  var transaction = UITransaction.current
  transaction.animation = animation
  if let completion {
    transaction.addAnimationCompletion(completion)
  }
  return try withUITransaction(transaction, body)
}

/// The way a view changes over time to create a smooth visual transition from one state to another.
public struct UIAnimation: Hashable, Sendable {
  fileprivate var delay: TimeInterval
  fileprivate var duration: TimeInterval
  fileprivate var options: UIView.AnimationOptions
  fileprivate var repeatModifier: RepeatModifier?
  fileprivate var speed: Double = 1
  fileprivate let style: Style

  @MainActor
  func perform<Result>(
    _ body: () throws -> Result,
    completion: ((Bool) -> Void)? = nil
  ) rethrows -> Result {
    func animations() throws -> Result {
      guard let repeatModifier else { return try body() }
      var result: Swift.Result<Result, Error>?
      UIView.modifyAnimations(
        withRepeatCount: repeatModifier.count,
        autoreverses: repeatModifier.autoreverses
      ) {
        result = Swift.Result(catching: body)
      }
      return try result!._rethrowGet()
    }
    switch style {
    case .iOS4:
      var result: Swift.Result<Result, Error>?
      withoutActuallyEscaping(animations) { animations in
        UIView.animate(
          withDuration: duration * speed,
          delay: delay * speed,
          options: options,
          animations: { result = Swift.Result(catching: animations) },
          completion: completion
        )
      }
      return try result!._rethrowGet()
    case let .iOS7(dampingRatio, velocity):
      var result: Swift.Result<Result, Error>?
      withoutActuallyEscaping(animations) { animations in
        UIView.animate(
          withDuration: duration * speed,
          delay: delay * speed,
          usingSpringWithDamping: dampingRatio,
          initialSpringVelocity: velocity,
          options: options,
          animations: { result = Swift.Result(catching: animations) },
          completion: completion
        )
      }
      return try result!._rethrowGet()

    case let .iOS17(bounce, initialSpringVelocity):
      if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
        var result: Swift.Result<Result, Error>?
        UIView.animate(
          springDuration: duration * speed,
          bounce: bounce,
          initialSpringVelocity: initialSpringVelocity,
          delay: delay * speed,
          options: options,
          animations: { result = Swift.Result(catching: animations) },
          completion: completion
        )
        return try result!._rethrowGet()
      } else {
        fatalError()
      }
    }
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

  public func delay(_ delay: TimeInterval) -> Self {
    var animation = self
    animation.delay += delay
    return animation
  }

  public func repeatCount(_ repeatCount: Int, autoreverses: Bool = true) -> Self {
    var animation = self
    animation.repeatModifier = RepeatModifier(
      autoreverses: autoreverses,
      count: CGFloat(repeatCount)
    )
    return animation
  }

  public func repeatForever(autoreverses: Bool = true) -> Self {
    var animation = self
    animation.repeatModifier = RepeatModifier(
      autoreverses: autoreverses,
      count: .infinity
    )
    return animation
  }

  public func speed(_ speed: Double) -> Self {
    var animation = self
    animation.speed = speed
    return animation
  }

  // TODO: `logicallyComplete(after duration: TimeInterval) -> Self`?

  public func hash(into hasher: inout Hasher) {
    hasher.combine(delay)
    hasher.combine(duration)
    hasher.combine(options.rawValue)
    hasher.combine(repeatModifier)
    hasher.combine(speed)
    hasher.combine(style)
  }
}

extension UIAnimation {
  public static func animate(
    withDuration duration: TimeInterval,
    delay: CGFloat = 0,
    options: UIView.AnimationOptions = []
  ) -> Self {
    Self(delay: delay, duration: duration, options: options, style: .iOS4)
  }

  public static func animate(
    withDuration duration: TimeInterval,
    delay: CGFloat = 0,
    usingSpringWithDamping dampingRatio: CGFloat,
    initialSpringVelocity velocity: CGFloat,
    options: UIView.AnimationOptions = []
  ) -> Self {
    Self(
      delay: delay,
      duration: duration,
      options: options,
      style: .iOS7(
        dampingRatio: dampingRatio,
        velocity: velocity
      )
    )
  }

  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  public static func animate(
    springDuration duration: TimeInterval = 0.5,
    bounce: CGFloat = 0,
    initialSpringVelocity: CGFloat = 0,
    delay: TimeInterval = 0,
    options: UIView.AnimationOptions = []
  ) -> Self {
    Self(
      delay: delay,
      duration: duration,
      options: options,
      style: .iOS17(
        bounce: bounce,
        initialSpringVelocity: initialSpringVelocity
      )
    )
  }

  public static var `default`: Self {
    if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
      return .animate()
    } else {
      return .animate(withDuration: 0.35)
    }
  }

  public static var linear: Self { .linear(duration: 0.35) }

  public static func linear(duration: TimeInterval) -> Self {
    .animate(withDuration: 0.35, options: .curveLinear)
  }

  public static var easeIn: Self { .easeIn(duration: 0.35) }

  public static func easeIn(duration: TimeInterval) -> Self {
    .animate(withDuration: 0.35, options: .curveEaseIn)
  }

  public static var easeOut: Self { .easeOut(duration: 0.35) }

  public static func easeOut(duration: TimeInterval) -> Self {
    .animate(withDuration: 0.35, options: .curveEaseOut)
  }

  public static var easeInOut: Self { .easeInOut(duration: 0.35) }

  public static func easeInOut(duration: TimeInterval) -> Self {
    .animate(withDuration: 0.35, options: .curveEaseInOut)
  }

  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  public static func interpolatingSpring(_ spring: Spring, initialVelocity: Double = 0) -> Self {
    .animate(
      springDuration: spring.damping,
      bounce: spring.bounce,
      initialSpringVelocity: initialVelocity
    )
  }

  // TODO: Is this right?
  // public static func interpolatingSpring(
  //   duration: TimeInterval = 0.5,
  //   bounce: Double = 0,
  //   initialVelocity: Double = 0
  // ) -> Self {
  //   .animate(
  //     withDuration: 0.5,
  //     usingSpringWithDamping: 1 - bounce,
  //     initialSpringVelocity: initialVelocity
  //   )
  // }

  // TODO: bouncy?
  // TODO: smooth?
  // TODO: snappy?
  // TODO: spring?
}
