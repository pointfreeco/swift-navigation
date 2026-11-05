#if canImport(AppKit) && !targetEnvironment(macCatalyst)

/// A value passed to a key path subscript, compared and hashed by identity.
///
/// The arguments of a key path subscript must be `Hashable`. A binding derived through such a
/// subscript — whether a set contains a member, or where a value sits among some options — would
/// otherwise demand that the member or the options be hashable too. Each binding wraps its own
/// argument, so identity is all the key path needs.
final class KeyPathArgument<Value>: Hashable, @unchecked Sendable {
  // NB: Unchecked, since the value need not be sendable. Bindings only read it on the main
  //     actor, and nothing ever changes it.
  let value: Value

  init(_ value: Value) {
    self.value = value
  }

  static func == (lhs: KeyPathArgument, rhs: KeyPathArgument) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

#endif
