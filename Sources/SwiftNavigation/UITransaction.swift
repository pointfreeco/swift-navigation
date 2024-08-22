import OrderedCollections

/// Executes a closure with the specified transaction and returns the result.
///
/// - Parameters:
///   - transaction: An instance of a transaction, set as the thread's current transaction.
///   - body: A closure to execute.
/// - Returns: The result of executing the closure with the specified transaction.
public func withUITransaction<Result>(
  _ transaction: UITransaction,
  _ body: () throws -> Result
) rethrows -> Result {
  try UITransaction.$current.withValue(
    UITransaction.current.merging(transaction),
    operation: body
  )
}

/// Executes a closure with the specified transaction key path and value and returns the result.
///
/// - Parameters:
///   - keyPath: A key path that indicates the property of the ``UITransaction`` structure to
///     update.
///   - value: The new value to set for the item specified by `keyPath`.
///   - body: A closure to execute.
/// - Returns: The result of executing the closure with the specified transaction value.
public func withUITransaction<R, V>(
  _ keyPath: WritableKeyPath<UITransaction, V>,
  _ value: V,
  _ body: () throws -> R
) rethrows -> R {
  var transaction = UITransaction()
  transaction[keyPath: keyPath] = value
  return try withUITransaction(transaction, body)
}

/// Use a transaction to pass an animation between views in a view hierarchy.
///
/// The root transaction for a state change comes from the binding that changed, plus any global
/// values set by calling ``withUITransaction(_:_:)``.
public struct UITransaction: Sendable {
  @TaskLocal package static var current = Self()

  var storage: OrderedDictionary<Key, any Sendable> = [:]

  /// Creates a transaction.
  public init() {}

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
    storage.isEmpty
  }

  fileprivate func merging(_ other: Self) -> Self {
    Self(storage: storage.merging(other.storage, uniquingKeysWith: { $1 }))
  }

  private init(storage: OrderedDictionary<Key, any Sendable>) {
    self.storage = storage
  }

  struct Key: Hashable {
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
public protocol UITransactionKey {
  /// The associated type representing the type of the transaction key's value.
  associatedtype Value: Sendable

  /// The default value for the transaction key.
  static var defaultValue: Value { get }
}

public protocol _UICustomTransactionKey: UITransactionKey, Sendable {
  static func perform(
    value: Value,
    operation: @Sendable () -> Void
  )
}
