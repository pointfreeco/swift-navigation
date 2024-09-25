#if compiler(>=6)
  public typealias _KeyPath<Root, Value> = any KeyPath<Root, Value> & Sendable
  public typealias _WritableKeyPath<Root, Value> = any WritableKeyPath<Root, Value> & Sendable
#else
  public typealias _KeyPath<Root, Value> = KeyPath<Root, Value>
  public typealias _WritableKeyPath<Root, Value> = WritableKeyPath<Root, Value>
#endif

func sendableKeyPath<Root, Value>(
  _ keyPath: WritableKeyPath<Root, Value>
) -> _WritableKeyPath<Root, Value> {
  unsafeBitCast(keyPath, to: _WritableKeyPath<Root, Value>.self)
}

func sendableKeyPath<Root, Value>(
  _ keyPath: KeyPath<Root, Value>
) -> _KeyPath<Root, Value> {
  unsafeBitCast(keyPath, to: _KeyPath<Root, Value>.self)
}
