struct Identified<ID: Hashable>: Identifiable {
  let id: ID
}

extension Optional {
  subscript<ID: Hashable>(id keyPath: KeyPath<Wrapped, ID>) -> Identified<ID>? {
    get { (self?[keyPath: keyPath]).map(Identified.init) }
    set { if newValue == nil { self = nil } }
  }
}
