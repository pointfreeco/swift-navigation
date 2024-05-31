import ConcurrencyExtras

@_spi(Observation)
public func observe(
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

/// A token for cancelling observation created with ``observe(_:task:)``.
public final class ObservationToken: Sendable, HashableObject {
  fileprivate let _isCancelled = LockIsolated(false)

  public var isCancelled: Bool {
    _isCancelled.value
  }

  /// Cancels observation that was created with ``observe(_:task:)``.
  ///
  /// > Note: This cancellation is lazy and cooperative. It does not cancel the observation
  /// > immediately, but rather next time a change is detected by ``observe(_:task:)`` it will cease
  /// > any future observation.
  public func cancel() {
    _isCancelled.setValue(true)
  }

  /// Stores this observation token instance in the specified collection.
  ///
  /// - Parameter collection: The collection in which to store this observation token.
  public func store(in collection: inout some RangeReplaceableCollection<ObservationToken>) {
    collection.append(self)
  }

  /// Stores this observation token instance in the specified set.
  ///
  /// - Parameter set: The set in which to store this observation token.
  public func store(in set: inout Set<ObservationToken>) {
    set.insert(self)
  }
}
