@propertyWrapper
package struct UncheckedSendable<Value>: @unchecked Sendable {
  package var wrappedValue: Value
  package var projectedValue: Self { self }
  package init(wrappedValue value: Value) {
    self.wrappedValue = value
  }
  package init(_ value: Value) {
    self.wrappedValue = value
  }
}
