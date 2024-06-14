import Foundation

final class LockIsolated<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = NSRecursiveLock()
  init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
    self._value = try value()
  }
  func withLock<T: Sendable>(
    _ operation: @Sendable (inout Value) throws -> T
  ) rethrows -> T {
    lock.lock()
    defer { lock.unlock() }
    var value = _value
    defer { _value = value }
    return try operation(&value)
  }
}
