import UIKit

/// Executes a closure with the specified transaction and returns the result.
///
/// - Parameters:
///   - transaction: An instance of a transaction, set as the thread's current transaction.
///   - body: A closure to execute.
/// - Returns: The result of executing the closure with the specified transaction.
@MainActor
public func withUITransaction<Result>(
  _ transaction: UITransaction,
  _ body: () throws -> Result
) rethrows -> Result {
  try UITransaction.$current.withValue(transaction, operation: body)
}

/// Executes a closure with the specified transaction key path and value and returns the result.
///
/// - Parameters:
///   - keyPath: A key path that indicates the property of the ``UITransaction`` structure to
///     update.
///   - value: The new value to set for the item specified by `keyPath`.
///   - body: A closure to execute.
/// - Returns: The result of executing the closure with the specified transaction value.
@MainActor
public func withUITransaction<R, V>(
  _ keyPath: WritableKeyPath<UITransaction, V>,
  _ value: V,
  _ body: () throws -> R
) rethrows -> R {
  var transaction = UITransaction.current
  transaction[keyPath: keyPath] = value
  return try withUITransaction(transaction, body)
}

/// Use a transaction to pass an animation between views in a view hierarchy.
///
/// The root transaction for a state change comes from the binding that changed, plus any global
/// values set by calling ``withUITransaction(_:_:)`` or ``withUIAnimation(_:_:)``.
@MainActor
public struct UITransaction {
  @TaskLocal static var current = Self()

  private var storage: [Key: Any] = [:]

  /// Creates a transaction.
  public init() {}

  /// Creates a transaction and assigns its animation property.
  ///
  /// - Parameter animation: The animation to perform when the current state changes.
  public init(animation: UIAnimation? = nil) {
    self.animation = animation
  }

  /// The animation, if any, associated with the current state change.
  public var animation: UIAnimation? {
    get { self[AnimationKey.self] }
    set { self[AnimationKey.self] = newValue }
  }

  /// A Boolean value that indicates whether views should disable animations.
  public var disablesAnimations: Bool {
    get { self[DisablesAnimationsKey.self] }
    set { self[DisablesAnimationsKey.self] = newValue }
  }

  // TODO: `criteria: UIAnimationCompletionCriteria`?
  /// Adds a completion to run when the animations created with this transaction are all complete.
  ///
  /// The completion callback will always be fired exactly one time.
  public mutating func addAnimationCompletion(_ completion: @escaping (Bool) -> Void) {
    animationCompletions.append(completion)
  }

  private var animationCompletions: [(Bool) -> Void] {
    get { self[AnimationCompletionsKey.self] }
    set { self[AnimationCompletionsKey.self] = newValue }
  }

  /// Accesses the transaction value associated with a custom key.
  ///
  /// Create custom transaction values by defining a key that conforms to the ``UITransactionKey``
  /// protocol, and then using that key with the subscript operator of the ``UITransaction``
  /// structure to get and set a value for that key:
  ///
  /// ```swift
  /// private struct MyTransactionKey: UITransactionKey {
  ///   static let defaultValue = false
  /// }
  ///
  ///
  /// extension UITransaction {
  ///   var myCustomValue: Bool {
  ///     get { self[MyTransactionKey.self] }
  ///     set { self[MyTransactionKey.self] = newValue }
  ///   }
  /// }
  /// ```
  public subscript<K: UITransactionKey>(key: K.Type) -> K.Value {
    get { storage[Key(key)] as? K.Value ?? key.defaultValue }
    set { storage[Key(key)] = newValue }
  }

  var isEmpty: Bool {
    // TODO: `storage.isEmpty?`
    animation == nil && !disablesAnimations
  }

  func perform<Result>(_ body: () throws -> Result) rethrows -> Result {
    if disablesAnimations {
      var result: Swift.Result<Result, Error>?
      UIView.performWithoutAnimation { result = Swift.Result(catching: body) }
      for completion in animationCompletions {
        completion(true)
      }
      return try result!._rethrowGet()
    } else if let animation {
      return try animation.perform(
        body,
        completion: animationCompletions.isEmpty
          ? nil
          : {
            for completion in animationCompletions {
              completion($0)
            }
          })
    } else {
      let result = Swift.Result(catching: body)
      for completion in animationCompletions {
        completion(true)
      }
      return try result._rethrowGet()
    }
  }

  private struct Key: Hashable {
    let keyType: Any.Type
    init<K: UITransactionKey>(_ keyType: K.Type) {
      self.keyType = keyType
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.keyType == rhs.keyType
    }
    func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(keyType))
    }
  }
}

/// A key for accessing values in a transaction.
///
/// Like SwiftUI's `TransactionKey` but for UIKit and other paradigms.
@MainActor
public protocol UITransactionKey {
  /// The associated type representing the type of the transaction key's value.
  associatedtype Value

  /// The default value for the transaction key.
  static var defaultValue: Value { get }
}

private enum AnimationKey: UITransactionKey {
  static let defaultValue: UIAnimation? = nil
}

private enum AnimationCompletionsKey: UITransactionKey {
  static var defaultValue: [(Bool) -> Void] = []
}

private enum DisablesAnimationsKey: UITransactionKey {
  static let defaultValue = false
}
