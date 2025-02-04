#if compiler(>=6)
  public typealias _SendableKeyPath<Root, Value> = any KeyPath<Root, Value> & Sendable
  public typealias _SendableWritableKeyPath<Root, Value> = any WritableKeyPath<Root, Value>
    & Sendable
#else
  public typealias _SendableKeyPath<Root, Value> = KeyPath<Root, Value>
  public typealias _SendableWritableKeyPath<Root, Value> = WritableKeyPath<Root, Value>
#endif

// NB: Dynamic member lookup does not currently support sendable key paths and even breaks
//     autocomplete.
//
//     * https://github.com/swiftlang/swift/issues/77035
//     * https://github.com/swiftlang/swift/issues/77105
extension _AppendKeyPath {
  @_transparent
  func unsafeSendable<Root, Value>() -> _SendableKeyPath<Root, Value>
  where Self == KeyPath<Root, Value> {
    #if compiler(>=6)
      unsafeBitCast(self, to: _SendableKeyPath<Root, Value>.self)
    #else
      self
    #endif
  }

  @_transparent
  func unsafeSendable<Root, Value>() -> _SendableWritableKeyPath<Root, Value>
  where Self == WritableKeyPath<Root, Value> {
    #if compiler(>=6)
      unsafeBitCast(self, to: _SendableWritableKeyPath<Root, Value>.self)
    #else
      self
    #endif
  }
}
