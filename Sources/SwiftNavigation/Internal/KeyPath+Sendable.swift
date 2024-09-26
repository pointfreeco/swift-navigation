#if compiler(>=6)
  public typealias _SendableKeyPath<Root, Value> = any KeyPath<Root, Value> & Sendable
  public typealias _SendableWritableKeyPath<Root, Value> = any WritableKeyPath<Root, Value>
    & Sendable
#else
  public typealias _SendableKeyPath<Root, Value> = KeyPath<Root, Value>
  public typealias _SendableWritableKeyPath<Root, Value> = WritableKeyPath<Root, Value>
#endif

func sendableKeyPath<Root, Value>(
  _ keyPath: KeyPath<Root, Value>
) -> _SendableKeyPath<Root, Value> {
  unsafeBitCast(keyPath, to: _SendableKeyPath<Root, Value>.self)
}

func sendableKeyPath<Root, Value>(
  _ keyPath: WritableKeyPath<Root, Value>
) -> _SendableWritableKeyPath<Root, Value> {
  unsafeBitCast(keyPath, to: _SendableWritableKeyPath<Root, Value>.self)
}
