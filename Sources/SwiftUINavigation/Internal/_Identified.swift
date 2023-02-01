import SwiftUI

enum _IdentifiedID: Hashable {
  case id(AnyHashable)
  case inferred(ObjectIdentifier, UInt32?)
}

struct _Identified<Value>: Identifiable {
  static func id(_ rawValue: Value) -> _IdentifiedID {
    if let id = identifiableID(value: rawValue) {
      return .id(id)
    } else {
      return .inferred(ObjectIdentifier(Value.self), enumTag(rawValue))
    }
  }

  var id: _IdentifiedID
  var rawValue: Value {
    didSet {
      self.id = Self.id(rawValue)
    }
  }

  init?<Optional: OptionalProtocol>(_ optional: Optional) where Optional.Wrapped == Value {
    guard let rawValue = optional.wrappedValue else { return nil }
    self.id = Self.id(rawValue)
    self.rawValue = rawValue
  }
  
  init?(rawValue: Value?, id: ID) {
    guard let rawValue = rawValue else { return nil }
    self.rawValue = rawValue
    self.id = id
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
    set { self = .init(wrappedValue: newValue?.rawValue) }
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

extension Binding {
  func `case`<Enum, Case>(_ casePath: CasePath<Enum, Case>) -> Binding<_Identified<Case>?>
  where Value == _Identified<Enum>? {
    return .init(
      get: {
        self.wrappedValue.flatMap { identified in
          casePath.extract(from: identified.rawValue).flatMap {
            _Identified(rawValue: $0, id: identified.id)
          }
        }
      },
      set: { newValue, transaction in
        self.transaction(transaction).wrappedValue = newValue
          .map(\.rawValue)
          .flatMap(casePath.embed(_:))
          .identified
      }
    )
  }
}

// TODO: Should we restrict to non-optional only?
private func enumTag<Case>(_ `case`: Case) -> UInt32? {
  let metadataPtr = unsafeBitCast(type(of: `case`), to: UnsafeRawPointer.self)
  let kind = metadataPtr.load(as: Int.self)
  let isEnumOrOptional = kind == 0x201 || kind == 0x202
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

#if swift(>=5.7)
func identifiableID(value: Any) -> AnyHashable? {
  if let value = value as? any Identifiable {
    return AnyHashable(value._id)
  }
  return nil
}
#else
private enum Witness<T> {}

private protocol AnyIdentifiable {
  static func id(_ lhs: Any) -> AnyHashable?
}

extension Witness: AnyIdentifiable where T: Identifiable {
  static func id(_ lhs: Any) -> AnyHashable? {
    guard let lhs = lhs as? T else { return nil }
    return AnyHashable(lhs.id)
  }
}

func identifiableID(value: Any) -> AnyHashable? {
  func open<T>(_: T.Type) -> AnyHashable? {
    (Witness<T>.self as? AnyIdentifiable.Type)?.id(value)
  }
  return _openExistential(type(of: value), do: open)
}
#endif



