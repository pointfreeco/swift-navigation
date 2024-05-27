import UIKit

extension NSObject {
  @discardableResult
  @MainActor
  public func observe(_ apply: @escaping @MainActor @Sendable () -> Void) -> ObservationToken {
    let token = UIKitNavigation.observe { transaction in
      transaction.perform {
        apply()
      }
    }
    tokens.insert(token)
    return token
  }

  fileprivate var tokens: Set<ObservationToken> {
    get {
      objc_getAssociatedObject(self, tokensKey) as? Set<ObservationToken> ?? []
    }
    set {
      objc_setAssociatedObject(self, tokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

private let tokensKey = malloc(1)!

@MainActor
public func observe(
  _ apply: @escaping @MainActor @Sendable (UITransaction) -> Void
) -> ObservationToken {
  var isCancelled = false
  let token = ObservationToken {
    isCancelled = true
  }
  onChange { transaction in
    guard !isCancelled else { return }
    apply(transaction)
  }
  return token
}

@MainActor
fileprivate func onChange(_ apply: @escaping @MainActor @Sendable (UITransaction) -> Void) {
  withPerceptionTracking {
    apply(UITransaction.current)
  } onChange: {
    let transaction = MainActor.assumeIsolated { UITransaction.current }
    DispatchQueue.main.async {
      UITransaction.$current.withValue(transaction) {
        onChange(apply)
      }
    }
  }
}

@MainActor
public final class ObservationToken: NSObject, Sendable {
  private let onCancel: @MainActor @Sendable () -> Void

  private(set) public var isCancelled = false

  init(cancel onCancel: @MainActor @Sendable @escaping () -> Void) {
    self.onCancel = onCancel
  }

  public func cancel() {
    guard !isCancelled else { return }
    defer { isCancelled = true }
    onCancel()
  }

  deinit {
    MainActor.assumeIsolated {
      cancel()
    }
  }
}
