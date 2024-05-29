import ConcurrencyExtras

package func observe(
  _ apply: @escaping @Sendable (UITransaction) -> Void,
  // TODO: Can we clean this up with an executor?
  task: @escaping @Sendable (UITransaction, @escaping @Sendable () -> Void) -> Void = {
    Task(operation: $1)
  }
) -> ObservationToken {
  let token = ObservationToken()
  onChange(
    { transaction in
      guard !token.isCancelled else { return }
      apply(transaction)
    },
    task: task
  )
  return token
}

private func onChange(
  _ apply: @escaping @Sendable (UITransaction) -> Void,
  task: @escaping @Sendable (UITransaction, @escaping @Sendable () -> Void) -> Void
) {
  withPerceptionTracking {
    apply(.current)
  } onChange: {
    task(.current) {
      onChange(apply, task: task)
    }
  }
}

public final class ObservationToken: Sendable, HashableObject {
  fileprivate let _isCancelled = LockIsolated(false)

  public var isCancelled: Bool {
    _isCancelled.value
  }

  public func cancel() {
    _isCancelled.setValue(true)
  }
}
