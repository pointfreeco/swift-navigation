extension Bool {
  struct Unit: Hashable, Identifiable {
    var id: Unit { self }
  }

  var toOptionalUnit: Unit? {
    get { self ? Unit() : nil }
    set { self = newValue != nil }
  }
}
