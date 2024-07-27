import ConcurrencyExtras

#if swift(>=6)
/// Tracks access to properties of an observable model.
///
/// This function allows one to minimally observe changes in a model in order to
/// react to those changes. For example, if you had an observable model like so:
///
/// ```swift
/// @Observable
/// class FeatureModel {
///   var count = 0
/// }
/// ```
///
/// Then you can use ``observe(_:)`` to observe changes in the model. For example, in UIKit you can
/// update a `UILabel`:
///
/// ```swift
/// observe { [weak self] in
///   guard let self else { return }
///
///   countLabel.text = "Count: \(model.count)"
/// }
/// ```
///
/// Anytime the `count` property of the model changes the trailing closure will be invoked again,
/// allowing you to update the view. Further, only changes to properties accessed in the trailing
/// closure will be observed.
///
/// > Note: If you are targeting Apple's older platforms (anything before iOS 17, macOS 14, tvOS 17,
/// watchOS 10), then you can use our [Perception](http://github.com/pointfreeco/swift-perception)
/// library to replace Swift's Observation framework.
///
/// This function also works on non-Apple platforms, such as Windows, Linux, Wasm, and more. For
/// example, in a Wasm app you could observe chnages to the `count` property to update the inner
/// HTML of a tag:
///
/// ```swift
/// import JavaScriptKit
/// 
/// var countLabel = document.createElement("span")
/// _ = document.body.appendChild(countLabel)
///
/// let token = observe { _ in
///   countLabel.innerText = .string("Count: \(model.count)")
/// }
/// ```
///
/// And you can also build your own tools on top of ``observe(_:)``.
///
/// - Parameter apply: A closure that contains properties to track.
/// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
/// is deallocated.
public func observe(
  @_inheritActorContext _ apply: @escaping @Sendable (_ transaction: UITransaction) -> Void,
  isolation: (any Actor)? = #isolation
) -> ObservationToken {
  let actor = ActorProxy(base: isolation)
  return observe(
    apply,
    task: { transaction, operation in
      Task {
        await actor.perform {
          operation()
        }
      }
    }
  )
}
#endif

actor ActorProxy {
  let base: (any Actor)?
  init(base: (any Actor)?) {
    self.base = base
  }
  nonisolated var unownedExecutor: UnownedSerialExecutor {
    (base ?? MainActor.shared).unownedExecutor
  }
  func perform(_ operation: @Sendable () -> Void) {
    operation()
  }
}

@_spi(Internals)
public func observe(
  _ apply: @escaping @Sendable (_ transaction: UITransaction) -> Void,
  task: @escaping @Sendable (
    _ transaction: UITransaction, _ operation: @escaping @Sendable () -> Void
  ) -> Void = {
    Task(operation: $1)
  }
) -> ObservationToken {
  let token = ObservationToken()
  onChange(
    { [weak token] transaction in
      guard
        let token,
        !token.isCancelled
      else { return }
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
}
