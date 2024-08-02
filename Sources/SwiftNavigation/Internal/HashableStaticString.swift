package struct HashableStaticString: Hashable {
  package var rawValue: StaticString

  package init(rawValue: StaticString) {
    self.rawValue = rawValue
  }

  package static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue.description == rhs.rawValue.description
  }

  package func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue.description)
  }
}
