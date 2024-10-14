#if compiler(>=6)
  public typealias _SendableKeyPath<Root, Value> = any KeyPath<Root, Value> & Sendable
  public typealias _SendableWritableKeyPath<Root, Value> = any WritableKeyPath<Root, Value>
    & Sendable
#else
  public typealias _SendableKeyPath<Root, Value> = KeyPath<Root, Value>
  public typealias _SendableWritableKeyPath<Root, Value> = WritableKeyPath<Root, Value>
#endif
