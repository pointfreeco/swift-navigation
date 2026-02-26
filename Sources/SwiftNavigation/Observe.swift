import ConcurrencyExtras

#if swift(>=6)
/// Tracks access to properties of an observable model.
///
/// A version of ``observe(_:onChange:)-(_,(T)->Void)`` that is handed the current ``UITransaction``.
///
/// - Parameter context: An autoclosure that returns property to track.
/// - Parameter apply: Invoked when the value of a property changes
///   > `onChange` is also invoked on initial call
/// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
///   is deallocated.
  public func observe<T>(
    @_inheritActorContext
    _ context: @escaping @isolated(any) @Sendable @autoclosure () -> T,
    @_inheritActorContext
    onChange apply: @escaping @isolated(any) @Sendable (UITransaction, T) -> Void
  ) -> ObserveToken {
    _observe(
      isolation: context.isolation,
      { _ in _assumeNotThrowing(call: context) },
      onChange: { _assumeNotThrowing(call: apply, with: $0, $1) }
    )
  }

  /// Tracks access to property of an observable model.
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
  /// Then you can use `observe` to observe changes in the model. For example, in UIKit you can
  /// update a `UILabel`:
  ///
  /// ```swift
  /// observe(model.count) { [countLabel] value in
  ///   countLabel.text = "Count: \(value)"
  /// }
  /// ```
  ///
  /// Anytime the `count` property of the model changes the trailing closure will be invoked again,
  /// allowing you to update the view. Further, only changes to properties accessed in the trailing
  /// closure will be observed.
  ///
  /// > Note: If you are targeting Apple's older platforms (anything before iOS 17, macOS 14,
  /// > tvOS 17, watchOS 10), then you can use our
  /// > [Perception](http://github.com/pointfreeco/swift-perception) library to replace Swift's
  /// > Observation framework.
  ///
  /// This function also works on non-Apple platforms, such as Windows, Linux, Wasm, and more. For
  /// example, in a Wasm app you could observe changes to the `count` property to update the inner
  /// HTML of a tag:
  ///
  /// ```swift
  /// import JavaScriptKit
  ///
  /// var countLabel = document.createElement("span")
  /// _ = document.body.appendChild(countLabel)
  ///
  /// let token = observe(model.count) { value in
  ///   countLabel.innerText = .string("Count: \(value)")
  /// }
  /// ```
  ///
  /// And you can also build your own tools on top of `observe`.
  ///
/// - Parameter context: An autoclosure that returns property to track.
  /// - Parameter apply: Invoked when the value of a property changes
  ///   > `onChange` is also invoked on initial call
  /// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
  ///   is deallocated.
  public func observe<T>(
    @_inheritActorContext
    _ context: @escaping @isolated(any) @Sendable @autoclosure () -> T,
    @_inheritActorContext
    onChange apply: @escaping @isolated(any) @Sendable (T) -> Void
  ) -> ObserveToken {
    _observe(
      isolation: context.isolation,
      { _ in _assumeNotThrowing(call: context) },
      onChange: { _assumeNotThrowing(call: apply, with: $1) }
    )
  }

  /// Tracks access to properties of an observable model.
  ///
  /// This function is a convenient variant of ``observe(_:onChange:)-(()->Void,_)`` that
  /// combines tracking context and onChange handler in one `apply` argument
  /// and allows one to minimally observe changes in a model in order to
  /// react to those changes. For example, if you had an observable model like so:
  ///
  /// ```swift
  /// @Observable
  /// class FeatureModel {
  ///   var count = 0
  /// }
  /// ```
  ///
  /// Then you can use `observe` to observe changes in the model. For example, in UIKit you can
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
  /// > Note: If you are targeting Apple's older platforms (anything before iOS 17, macOS 14,
  /// > tvOS 17, watchOS 10), then you can use our
  /// > [Perception](http://github.com/pointfreeco/swift-perception) library to replace Swift's
  /// > Observation framework.
  ///
  /// This function also works on non-Apple platforms, such as Windows, Linux, Wasm, and more. For
  /// example, in a Wasm app you could observe changes to the `count` property to update the inner
  /// HTML of a tag:
  ///
  /// ```swift
  /// import JavaScriptKit
  ///
  /// var countLabel = document.createElement("span")
  /// _ = document.body.appendChild(countLabel)
  ///
  /// let token = observe {
  ///   countLabel.innerText = .string("Count: \(model.count)")
  /// }
  /// ```
  ///
  /// And you can also build your own tools on top of `observe`.
  ///
  /// - Parameter apply: A closure that contains properties to track.
  /// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
  ///   is deallocated.
  public func observe(
    @_inheritActorContext
    _ apply: @escaping @isolated(any) @Sendable () -> Void
  ) -> ObserveToken {
    _observe(
      isolation: apply.isolation,
      { _ in _assumeNotThrowing(call: apply) }
    )
  }

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
  /// Then you can use `observe` to observe changes in the model. For example, in UIKit you can
  /// update a `UILabel`:
  ///
  /// ```swift
  /// observe { [model] in model.count } onChange: { [countLabel, model] in
  ///   countLabel.text = "Count: \(model.count)"
  /// }
  /// ```
  ///
  /// Anytime the `count` property of the model changes the trailing closure will be invoked again,
  /// allowing you to update the view. Further, only changes to properties accessed in the trailing
  /// closure will be observed.
  ///
  /// > Note: If you are targeting Apple's older platforms (anything before iOS 17, macOS 14,
  /// > tvOS 17, watchOS 10), then you can use our
  /// > [Perception](http://github.com/pointfreeco/swift-perception) library to replace Swift's
  /// > Observation framework.
  ///
  /// This function also works on non-Apple platforms, such as Windows, Linux, Wasm, and more. For
  /// example, in a Wasm app you could observe changes to the `count` property to update the inner
  /// HTML of a tag:
  ///
  /// ```swift
  /// import JavaScriptKit
  ///
  /// var countLabel = document.createElement("span")
  /// _ = document.body.appendChild(countLabel)
  ///
  /// let token = observe { model.count } onChange: {
  ///   countLabel.innerText = .string("Count: \(model.count)")
  /// }
  /// ```
  ///
  /// And you can also build your own tools on top of `observe`.
  ///
  /// - Parameter context: A closure that contains properties to track.
  /// - Parameter apply: Invoked when the value of a property changes
  ///   > `onChange` is also invoked on initial call
  /// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
  ///   is deallocated.
  public func observe(
    @_inheritActorContext
    _ context: @escaping @isolated(any) @Sendable () -> Void,
    @_inheritActorContext
    onChange apply: @escaping @isolated(any) @Sendable () -> Void
  ) -> ObserveToken {
    _observe(
      isolation: context.isolation,
      { _ in _assumeNotThrowing(call: context) },
      onChange: { _, _ in _assumeNotThrowing(call: apply) }
    )
  }

  /// Tracks access to properties of an observable model.
  ///
  /// A version of ``observe(_:)-(()->Void)`` that is handed the current ``UITransaction``.
  ///
  /// - Parameter apply: A closure that contains properties to track.
  /// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
  ///   is deallocated.
  public func observe(
    @_inheritActorContext
    _ apply: @escaping @isolated(any) @Sendable (_ transaction: UITransaction) -> Void
  ) -> ObserveToken {
    _observe(
      isolation: apply.isolation,
      apply
    )
  }

  /// Tracks access to properties of an observable model.
  ///
  /// A version of ``observe(_:onChange:)-(()->Void,_)`` that is handed the current ``UITransaction``.
  ///
  /// - Parameter context: A closure that contains properties to track.
  /// - Parameter apply: Invoked when the value of a property changes
  ///   > `onChange` is also invoked on initial call
  /// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
  ///   is deallocated.
  public func observe(
    @_inheritActorContext
    _ context: @escaping @isolated(any) @Sendable (_ transaction: UITransaction) -> Void,
    @_inheritActorContext
    onChange apply: @escaping @isolated(any) @Sendable (_ transaction: UITransaction) -> Void
  ) -> ObserveToken {
    _observe(
      isolation: context.isolation,
      context,
      onChange: { transaction, _ in
        _assumeNotThrowing(call: apply, with: transaction)
      }
    )
  }
#endif

// MARK: - _observe
// Actual isolation is guaranteed here

/// Observes changes in given context
///
/// - Parameter apply: Invoked when a change occurs in observed context
///   > `apply` is also invoked on initial call
/// - Parameter task: The task that wraps recursive observation calls
/// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
///   is deallocated.
func _observe(
  isolation: (any Actor)?,
  _ apply: @escaping @Sendable (_ transaction: UITransaction) -> Void
) -> ObserveToken {
  let actor = ActorProxy(base: isolation)
  let token = onChange(
    apply,
    task: { transaction, operation in
      Task {
        await actor.perform {
          operation()
        }
      }
    }
  )

  return token
}

/// Observes changes in given context
///
/// - Parameter context: Observed context
/// - Parameter apply: Invoked when a change occurs in observed context
///   > `onChange` is also invoked on initial call
/// - Parameter task: The task that wraps recursive observation calls
/// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
///   is deallocated.
func _observe<T>(
  isolation: (any Actor)?,
  _ context: @escaping @Sendable (_ transaction: UITransaction) -> T,
  onChange apply: @escaping @Sendable (_ transaction: UITransaction, T) -> Void
) -> ObserveToken {
  let actor = ActorProxy(base: isolation)
  let observation = onChange(
    of: context,
    perform: apply,
    task: { transaction, operation in
      Task {
        await actor.perform {
          operation()
        }
      }
    }
  )

  apply(.current, observation.initialValue)
  return observation.token
}

// MARK: - onChange
// UITransaction & cancellation integration to recursive perception tracking

/// Observes changes in given context
///
/// - Parameter context: Observed context
/// - Parameter operation: Invoked when a change occurs in observed context
///   > `operation` is not invoked on initial call
/// - Parameter task: The task that wraps recursive observation calls
/// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
///   is deallocated.
func onChange(
  _ apply: @escaping @Sendable (_ transaction: UITransaction) -> Void,
  task: @escaping @Sendable (
    _ transaction: UITransaction,
    _ operation: @escaping @Sendable () -> Void
  ) -> Void = {
    Task(operation: $1)
  }
) -> ObserveToken {
  let token = ObserveToken()
  SwiftNavigation.withRecursivePerceptionTracking(
    { [weak token] transaction in
      guard
        let token,
        !token.isCancelled
      else { return }

      var perform: @Sendable () -> Void = { apply(transaction) }
      for key in transaction.storage.keys {
        guard let keyType = key.keyType as? any _UICustomTransactionKey.Type
        else { continue }
        func open<K: _UICustomTransactionKey>(_: K.Type) {
          perform = { [perform] in
            K.perform(value: transaction[K.self]) {
              perform()
            }
          }
        }
        open(keyType)
      }
      perform()
    },
    task: task
  )
  return token
}

/// Observes changes in given context
///
/// - Parameter context: Observed context
/// - Parameter operation: Invoked when a change occurs in observed context
///   > `operation` is not invoked on initial call
/// - Parameter task: The task that wraps recursive observation calls
/// - Returns: A token that keeps the subscription alive. Observation is cancelled when the token
///   is deallocated.
func onChange<T>(
  of context: @escaping @Sendable (_ transaction: UITransaction) -> T,
  perform operation: @escaping @Sendable (_ transaction: UITransaction, T) -> Void,
  task: @escaping @Sendable (
    _ transaction: UITransaction,
    _ operation: @escaping @Sendable () -> Void
  ) -> Void = {
    Task(operation: $1)
  }
) -> (token: ObserveToken, initialValue: T) {
  let token = ObserveToken()

  // Token is just initialized and strongly held, value is effectively
  // runtime-guaranteed
  let initialValue: T! = SwiftNavigation.withRecursivePerceptionTracking(
    of: { [weak token] transaction in
      guard let token, !token.isCancelled else { return nil }
      return context(transaction)
    },
    perform: { [weak token] transaction, value in
      guard
        let token,
        let value,
        !token.isCancelled
      else { return }

      let uncheckedSendableValue = UncheckedSendable(value)

      var perform: @Sendable () -> Void = { operation(transaction, uncheckedSendableValue.value) }
      for key in transaction.storage.keys {
        guard let keyType = key.keyType as? any _UICustomTransactionKey.Type
        else { continue }
        func open<K: _UICustomTransactionKey>(_: K.Type) {
          perform = { [perform] in
            K.perform(value: transaction[K.self]) {
              perform()
            }
          }
        }
        open(keyType)
      }
      perform()
    },
    task: task
  )
  return (token, initialValue)
}

// MARK: - Perception
// Low level functions for recursive perception tracking

private func withRecursivePerceptionTracking(
  _ apply: @escaping @Sendable (_ transaction: UITransaction) -> Void,
  task: @escaping @Sendable (
    _ transaction: UITransaction,
    _ operation: @escaping @Sendable () -> Void
  ) -> Void
) {
  withPerceptionTracking {
    apply(.current)
  } onChange: {
    task(.current) {
      withRecursivePerceptionTracking(apply, task: task)
    }
  }
}

private func withRecursivePerceptionTracking<T>(
  of context: @escaping @Sendable (_ transaction: UITransaction) -> T,
  perform operation: @escaping @Sendable (_ transaction: UITransaction, T) -> Void,
  task: @escaping @Sendable (
    _ transaction: UITransaction,
    _ operation: @escaping @Sendable () -> Void
  ) -> Void
) -> T {
  withPerceptionTracking {
    context(.current)
  } onChange: {
    task(.current) {
      operation(.current, withRecursivePerceptionTracking(
        of: context,
        perform: operation,
        task: task
      ))
    }
  }
}

// MARK: - ObserveToken

/// A token for cancelling observation.
///
/// When this token is deallocated it cancels the observation it was associated with. Store this
/// token in another object to keep the observation alive. You can do with this with a set of
/// ``ObserveToken``s and the ``store(in:)-4bp5r`` method:
///
/// ```swift
/// class Coordinator {
///   let model = Model()
///   var tokens: Set<ObserveToken> = []
///
///   func start() {
///     observe { [weak self] in
///       // ...
///     }
///     .store(in: &tokens)
///   }
/// }
/// ```
public final class ObserveToken: Sendable, HashableObject {
  fileprivate let _isCancelled = LockIsolated(false)
  public let onCancel: @Sendable () -> Void

  public var isCancelled: Bool {
    _isCancelled.withValue { $0 }
  }

  public init(onCancel: @escaping @Sendable () -> Void = {}) {
    self.onCancel = onCancel
  }

  deinit {
    cancel()
  }

  /// Cancels observation that was created with ``observe(isolation:_:)-9xf99``.
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
  public func store(in collection: inout some RangeReplaceableCollection<ObserveToken>) {
    collection.append(self)
  }

  /// Stores this observation token instance in the specified set.
  ///
  /// - Parameter set: The set in which to store this observation token.
  public func store(in set: inout Set<ObserveToken>) {
    set.insert(self)
  }
}

// MARK: - ActorProxy

private actor ActorProxy {
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

// MARK: Isolation workaround

private func _assumeNotThrowing<each Arg, Output>(
  call body: (repeat each Arg) throws(Error) -> Output,
  with args: repeat each Arg
) -> Output {
  try! body(repeat each args)
}
