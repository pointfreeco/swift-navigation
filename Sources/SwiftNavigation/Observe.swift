import ConcurrencyExtras

@_spi(Internals)
public func observe(
  _ apply: @escaping @Sendable (_ transaction: UITransaction) -> Void,
  // TODO: Can we clean this up with an executor?
  task: @escaping @Sendable (
    _ transaction: UITransaction, _ operation: @escaping @Sendable () -> Void
  ) -> Void = {
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
  _ apply: @escaping @Sendable (_ transaction: UITransaction) -> Void,
  task: @escaping @Sendable (
    _ transaction: UITransaction, _ operation: @escaping @Sendable () -> Void
  ) -> Void
) {
  withPerceptionTracking {
    apply(.current)
  } onChange: {
    task(.current) {
      onChange(apply, task: task)
    }
  }
}

/// A token for cancelling observation.
public final class ObservationToken: Sendable, HashableObject {
  fileprivate let _isCancelled = LockIsolated(false)
  private let onCancel: @Sendable () -> Void

  public var isCancelled: Bool {
    _isCancelled.withValue { $0 }
  }

  public init(onCancel: @escaping @Sendable () -> Void = {}) {
    self.onCancel = onCancel
  }

  deinit {
    cancel()
  }

  /// Cancels observation that was created with ``UIKitNavigation/observe(_:)``.
  ///
  /// > Note: This cancellation is lazy and cooperative. It does not cancel the observation
  /// > immediately, but rather next time a change is detected by `observe` it will cease any future
  /// > observation.
  public func cancel() {
    _isCancelled.withValue { isCancelled in
      guard !isCancelled else { return }
      defer { isCancelled = true }
      onCancel()
    }
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

  // TODO: Add `store(in object: NSObject)`?
}
