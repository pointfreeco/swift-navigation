import Foundation

/// A type-erased list of data representing the content of a navigation stack.
///
/// Like SwiftUI's `NavigationPath`, but for UIKit and other paradigms.
public struct UINavigationPath: Equatable {
  package var elements: [AnyHashable]

  /// The number of elements in this path.
  public var count: Int {
    elements.count
  }

  /// A Boolean that indicates whether this path is empty.
  public var isEmpty: Bool {
    elements.isEmpty
  }

  /// A value that describes the contents of this path in a serializable format.
  ///
  /// This value is `nil` if any of the type-erased elements of the path don’t conform to the
  /// `Codable` protocol.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public var codable: CodableRepresentation? {
    CodableRepresentation(self)
  }

  /// Creates a new, empty navigation path.
  public init() {
    self.elements = []
  }

  /// Creates a new navigation path from the contents of a sequence.
  ///
  /// - Parameter elements: A sequence used to create the navigation path.
  public init<S: Sequence>(_ elements: S) where S.Element: Hashable {
    self.elements = elements.map(AnyHashable.init)
  }

  /// Creates a new navigation path from a serializable version.
  ///
  /// - Parameter codable: A value describing the contents of the new path in a serializable format.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public init(_ codable: CodableRepresentation) {
    self.elements = codable.elements.map(\.value)
  }

  /// Appends a new value to the end of this path.
  public mutating func append<V: Hashable>(_ value: V) {
    elements.append(value)
  }

  /// Removes values from the end of this path.
  ///
  /// - Parameter k: The number of values to remove. The default value is `1`.
  /// - Precondition: The input parameter `k` must be greater than or equal to zero, and must be
  ///   less than or equal to the number of elements in the path.
  public mutating func removeLast(_ k: Int = 1) {
    elements.removeLast(k)
  }

  /// A serializable representation of a navigation path.
  ///
  /// When a navigation path contains elements the conform to the `Codable` protocol, you can use
  /// the path's `CodableRepresentation` to convert the path to an external representation and to
  /// convert an external representation back into a navigation path.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public struct CodableRepresentation: Codable, Equatable {
    fileprivate struct Element: Equatable {
      let type: Any.Type
      let value: AnyHashable

      static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.value == rhs.value
      }
    }

    fileprivate var elements: [Element] = []

    fileprivate init?(_ path: UINavigationPath) {
      elements.reserveCapacity(path.elements.count)
      for value in path.elements.reversed() {
        guard value.base is Encodable else { return nil }
        elements.insert(Element(type: type(of: value.base), value: value), at: 0)
      }
    }

    public init(from decoder: any Decoder) throws {
      var container = try decoder.unkeyedContainer()
      if let count = container.count {
        elements.reserveCapacity(count)
      }
      while !container.isAtEnd {
        let typeName = try container.decode(String.self)
        // TODO: Only allow types that have been used with navigationDestination?
        guard let type = _typeByName(typeName) as? any Decodable.Type
        else {
          throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "\(typeName) is not decodable."
          )
        }
        let encodedValue = try container.decode(String.self)
        #if swift(<5.7)
          func decode<A: Decodable>(_: A.Type) throws -> A {
            try JSONDecoder().decode(A.self, from: Data(encodedValue.utf8))
          }
          let value = try _openExistential(type, do: decode)
        #else
          let value = try JSONDecoder().decode(type, from: Data(encodedValue.utf8))
        #endif
        guard let value = value as? AnyHashable
        else {
          throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "\(typeName) is not hashable."
          )
        }
        elements.insert(Element(type: type, value: value), at: 0)
      }
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.unkeyedContainer()
      for element in elements.reversed() {
        try container.encode(_mangledTypeName(element.type))
        guard let value = element.value as? any Encodable
        else {
          throw EncodingError.invalidValue(
            element,
            .init(
              codingPath: container.codingPath,
              debugDescription: "\(type(of: element)) is not encodable."
            )
          )
        }

        #if swift(<5.7)
          func open<A: Encodable>(_: A.Type) throws -> Data {
            try JSONEncoder().encode(element as! A)
          }
          let string = try String(
            decoding: _openExistential(type(of: element), do: open),
            as: UTF8.self
          )
          try container.encode(string)
        #else
          let string = try String(decoding: JSONEncoder().encode(value), as: UTF8.self)
          try container.encode(string)
        #endif
      }
    }
  }
}
