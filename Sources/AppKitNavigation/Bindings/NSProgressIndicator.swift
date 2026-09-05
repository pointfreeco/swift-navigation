#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit
public import SwiftNavigation

extension NSProgressIndicator {
  /// Creates a new progress indicator with the specified frame and registers the binding against
  /// its animation state.
  ///
  /// - Parameters:
  ///   - frame: The frame rectangle for the view, measured in points.
  ///   - isAnimated: The binding to read from for whether the indicator should animate.
  public convenience init(frame: CGRect = .zero, isAnimated: UIBinding<Bool>) {
    self.init(frame: frame)
    bind(isAnimated: isAnimated)
  }

  /// Establishes a connection between a binding and the progress indicator's animation state.
  ///
  /// - Parameter isAnimated: The binding to read from for whether the indicator should animate.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind(isAnimated: UIBinding<Bool>) -> ObserveToken {
    unbindIsAnimated()
    let token = observe { [weak self] in
      guard let self else { return }
      if isAnimated.wrappedValue {
        startAnimation(nil)
      } else {
        stopAnimation(nil)
      }
    }
    // NB: The token has to be retained by the progress indicator itself. Returning a freshly
    //     created token would cancel the observation the moment the caller discarded it, which
    //     'bind' is marked '@discardableResult' to encourage.
    let observationToken = ObserveToken { token.cancel() }
    isAnimatedToken = observationToken
    return observationToken
  }

  /// Cancels the connection established by ``bind(isAnimated:)``.
  public func unbindIsAnimated() {
    isAnimatedToken?.cancel()
    isAnimatedToken = nil
  }

  private var isAnimatedToken: ObserveToken? {
    get { objc_getAssociatedObject(self, Self.isAnimatedTokenKey) as? ObserveToken }
    set {
      objc_setAssociatedObject(
        self, Self.isAnimatedTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  private static let isAnimatedTokenKey = malloc(1)!
}

#endif
