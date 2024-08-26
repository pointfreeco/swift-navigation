extension Bool {
  package struct Unit: Hashable, Identifiable {
    package var id: Unit { self }

    package init() {}
  }

  package var toOptionalUnit: Unit? {
    get { self ? Unit() : nil }
    set { self = newValue != nil }
  }
}
