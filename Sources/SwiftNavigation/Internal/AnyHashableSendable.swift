package struct AnyHashableSendable: Hashable, Sendable {
  package let base: any Hashable & Sendable

  @_disfavoredOverload
  package init(_ base: any Hashable & Sendable) {
    self.init(base)
  }

  package init(_ base: some Hashable & Sendable) {
    if let base = base as? AnyHashableSendable {
      self = base
    } else {
      self.base = base
    }
  }

  package static func == (lhs: Self, rhs: Self) -> Bool {
    AnyHashable(lhs.base) == AnyHashable(rhs.base)
  }

  package func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

extension AnyHashableSendable: CustomDebugStringConvertible {
  package var debugDescription: String {
    "AnyHashableSendable(" + String(reflecting: base) + ")"
  }
}

extension AnyHashableSendable: CustomReflectable {
  package var customMirror: Mirror {
    Mirror(self, children: ["value": base])
  }
}

extension AnyHashableSendable: CustomStringConvertible {
  package var description: String {
    String(describing: base)
  }
}

extension AnyHashableSendable: _HasCustomAnyHashableRepresentation {
  package func _toCustomAnyHashable() -> AnyHashable? {
    base as? AnyHashable
  }
}

extension AnyHashableSendable: ExpressibleByBooleanLiteral {
  package init(booleanLiteral value: Bool) {
    self.init(value)
  }
}

extension AnyHashableSendable: ExpressibleByFloatLiteral {
  package init(floatLiteral value: Double) {
    self.init(value)
  }
}

extension AnyHashableSendable: ExpressibleByIntegerLiteral {
  package init(integerLiteral value: Int) {
    self.init(value)
  }
}

extension AnyHashableSendable: ExpressibleByStringLiteral {
  package init(stringLiteral value: String) {
    self.init(value)
  }
}
