struct Identified<ID: Hashable, Value>: Identifiable {
  let id: ID
  let initialValue: Value
}

extension Optional {
  subscript<ID: Hashable>(id keyPath: KeyPath<Wrapped, ID>) -> Identified<ID, Wrapped>? {
    get { self.map { Identified(id: $0[keyPath: keyPath], initialValue: $0) } }
    set { if newValue == nil { self = nil } }
  }
}
