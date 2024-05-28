#if canImport(Dispatch)
  import Dispatch
#endif

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
private func onChange(_ apply: @escaping @MainActor @Sendable (UITransaction) -> Void) {
  withPerceptionTracking {
    apply(UITransaction.current)
  } onChange: {
    let transaction = MainActor.assumeIsolated { UITransaction.current }
    func task(operation: @escaping @MainActor @Sendable () -> Void) {
      #if canImport(Dispatch)
        DispatchQueue.main.async(execute: operation)
      #else
        Task(operation: operation)
      #endif
    }
    task {
      UITransaction.$current.withValue(transaction) {
        onChange(apply)
      }
    }
  }
}

@MainActor
public final class ObservationToken: Sendable {
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
