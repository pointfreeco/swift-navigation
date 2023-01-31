struct _Identified<Value>: Identifiable {
  enum ID: Hashable {
    case id(AnyHashable)
    case inferred(ObjectIdentifier, UInt32?)
  }

  let id: ID
  let wrappedValue: Value

  init?<Optional: OptionalProtocol>(_ optional: Optional) where Optional.Wrapped == Value {
    guard let value = optional.wrappedValue else { return nil }
    if let identifiable = value as? any Identifiable {
      self.id = .id(AnyHashable(identifiable._id))
    } else {
      self.id = .inferred(ObjectIdentifier(Value.self), enumTag(value))
    }
    self.wrappedValue = value
  }
}

protocol OptionalProtocol {
  associatedtype Wrapped
  var wrappedValue: Wrapped? { get set }
  init(wrappedValue: Wrapped?)
}

extension OptionalProtocol {
  // Used to derive a `Binding<_Identified<Wrapped>?> from `Binding<Wrapped?>`
  var identified: _Identified<Wrapped>? {
    get { _Identified(self.wrappedValue) }
    set { self = .init(wrappedValue: newValue?.wrappedValue) }
  }
}

extension Optional: OptionalProtocol {
  init(wrappedValue: Wrapped?) {
    self = wrappedValue
  }
  var wrappedValue: Wrapped? {
    get { self }
    set { self = newValue }
  }
}

extension Identifiable {
  // The compiler is lost with `(any Identifiable).id`.
  var _id: ID { self.id }
}

// TODO: Should we restrict to non-optional only?
private func enumTag<Case>(_ `case`: Case) -> UInt32? {
  let metadataPtr = unsafeBitCast(type(of: `case`), to: UnsafeRawPointer.self)
  let kind = metadataPtr.load(as: Int.self)
  let isEnumOrOptional = kind == 0x201
  guard isEnumOrOptional else { return nil }
  let vwtPtr = (metadataPtr - MemoryLayout<UnsafeRawPointer>.size).load(as: UnsafeRawPointer.self)
  let vwt = vwtPtr.load(as: EnumValueWitnessTable.self)
  return withUnsafePointer(to: `case`) { vwt.getEnumTag($0, metadataPtr) }
}

private struct EnumValueWitnessTable {
  let f1, f2, f3, f4, f5, f6, f7, f8: UnsafeRawPointer
  let f9, f10: Int
  let f11, f12: UInt32
  let getEnumTag: @convention(c) (UnsafeRawPointer, UnsafeRawPointer) -> UInt32
  let f13, f14: UnsafeRawPointer
}
