import class Foundation.NSLock

package final class LockIsolated<Value>: @unchecked Sendable {
  private var value: Value
  private let lock = NSLock()
  package init(_ value: sending Value) {
    self.value = value
  }
  package func withLock<R, F: Error>(
    _ operation: (inout sending Value) throws(F) -> sending R
  ) throws(F) -> sending R {
    lock.lock()
    defer { lock.unlock() }
    return try operation(&value)
  }
}
