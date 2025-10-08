#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import SwiftNavigation

extension NSProgressIndicator {
  
  public convenience init(frame: CGRect = .zero, isAnimated: UIBinding<Bool>) {
    self.init(frame: frame)
    bind(isAnimated: isAnimated)
  }
  
  @discardableResult
  public func bind(isAnimated: UIBinding<Bool>) -> ObserveToken {
    let token = observe { [weak self] in
      guard let self else { return }
      let isAnimated = isAnimated.wrappedValue
      if isAnimated {
        startAnimation(nil)
      } else {
        stopAnimation(nil)
      }
    }
    
    let observeToken = ObserveToken {
      token.cancel()
    }
    return observeToken
  }
  
}

#endif
