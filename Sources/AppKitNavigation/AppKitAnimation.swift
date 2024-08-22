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
    @available(macOS 15, *)
    public init(_ animation: Animation) {
      self.init(framework: .swiftUI(animation))
    }

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

    public static var `default`: Self {
      return .animate()
    }
  }
#endif
