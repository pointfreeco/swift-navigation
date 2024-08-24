#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit

  #if canImport(SwiftUI)
    import SwiftUI
  #endif

  import SwiftNavigation

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
        #if swift(>=6)
          var result: Swift.Result<Result, Error>?
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
    @available(macOS 15, *)
    public init(_ animation: Animation) {
      self.init(framework: .swiftUI(animation))
    }

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

    public static var `default`: Self {
      .animate()
    }

    public static var linear: Self { .linear(duration: 0.25) }

    public static func linear(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .linear))
    }

    public static var easeIn: Self { .easeIn(duration: 0.25) }

    public static func easeIn(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .easeIn))
    }

    public static var easeOut: Self { .easeOut(duration: 0.25) }

    public static func easeOut(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .easeOut))
    }

    public static var easeInOut: Self { .easeInOut(duration: 0.25) }

    public static func easeInOut(duration: TimeInterval) -> Self {
      .animate(duration: duration, timingFunction: CAMediaTimingFunction(name: .easeInEaseOut))
    }
  }
#endif
