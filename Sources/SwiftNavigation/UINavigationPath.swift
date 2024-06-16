import Foundation

/// A type-erased list of data representing the content of a navigation stack.
///
/// Like SwiftUI's `NavigationPath`, but for UIKit and other paradigms.
public struct UINavigationPath: Equatable {
  @_spi(Internals)
  public var elements: [Element] = []

  @_spi(Internals)
  public enum Element: Equatable {
    case eager(AnyHashable)
    case lazy(CodableRepresentation.Element)

    package var elementType: Any.Type? {
      switch self {
      case let .eager(value):
        return type(of: value.base)
      case let .lazy(value):
        return value.decodableType
      }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case let (.eager(lhs), .eager(rhs)):
        return lhs == rhs
      case let (.lazy(lhs), .lazy(rhs)):
        return lhs == rhs
      case let (.eager(eager), .lazy(lazy)), let (.lazy(lazy), .eager(eager)):
        guard #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) else { fatalError() }
        return CodableRepresentation.Element(eager) == lazy
      }
    }
  }

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
  /// This value is `nil` if any of the type-erased elements of the path don't conform to the
  /// `Codable` protocol.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public var codable: CodableRepresentation? {
    CodableRepresentation(self)
  }

  /// Creates a new, empty navigation path.
  public init() {}

  /// Creates a new navigation path from the contents of a sequence.
  ///
  /// - Parameter elements: A sequence used to create the navigation path.
  public init<S: Sequence>(_ elements: S) where S.Element: Hashable {
    self.elements = elements.map { .eager(AnyHashable($0)) }
  }

  /// Creates a new navigation path from a serializable version.
  ///
  /// - Parameter codable: A value describing the contents of the new path in a serializable format.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public init(_ codable: CodableRepresentation) {
    self.elements = codable.elements.map { .lazy($0) }
  }

  /// Appends a new value to the end of this path.
  public mutating func append<V: Hashable>(_ value: V) {
    elements.append(.eager(value))
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
  public struct CodableRepresentation: Codable, Equatable {
    @_spi(Internals)
    public struct Element: Hashable {
      static let decoder = JSONDecoder()
      static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
      }()

      let tag: String
      let item: String

      public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.tag == rhs.tag && lhs.item == rhs.item
      }

      public init(tag: String, item: String) {
        self.tag = tag
        self.item = item
      }

      var decodableType: (any Decodable.Type)? {
        _typeByName(tag) as? any Decodable.Type
      }

      @available(iOS 14, macOS 11, tvOS 15, watchOS 7, *)
      init?(_ value: AnyHashable) {
        func item() -> String? {
          guard let value = value as? any Encodable else { return nil }
          #if swift(<5.7)
            func open<A: Encodable>(_: A.Type) throws -> Data {
              try Self.encoder.encode(element as! A)
            }
            return try? String(
              decoding: _openExistential(type(of: element), do: open),
              as: UTF8.self
            )
          #else
            return try? String(decoding: Self.encoder.encode(value), as: UTF8.self)
          #endif
        }
        guard
          let tag = _mangledTypeName(type(of: value.base)),
          let item = item()
        else { return nil }
        self.init(tag: tag, item: item)
      }

      package func decode() -> AnyHashable? {
        func value(as type: any Decodable.Type) -> AnyHashable? {
          #if swift(<5.7)
            func open<A: Decodable>(_: A.Type)  A? {
              try Self.decoder.decode(A.self, from: Data(item.utf8)) as? AnyHashable
            }
            return try? _openExistential(type, do: open)
          #else
            return try? Self.decoder.decode(type, from: Data(item.utf8)) as? AnyHashable
          #endif
        }
        guard
          let type = decodableType,
          let value = value(as: type)
        else {
          return nil
        }
        return value
      }
    }

    fileprivate var elements: [Element] = []

    @available(iOS 14, macOS 11, tvOS 15, watchOS 7, *)
    fileprivate init?(_ path: UINavigationPath) {
      elements.reserveCapacity(path.elements.count)
      for element in path.elements {
        switch element {
        case let .eager(value):
          guard let element = Element(value) else { return nil }
          elements.append(element)
        case let .lazy(element):
          elements.append(element)
        }
      }
    }

    public init(from decoder: any Decoder) throws {
      var container = try decoder.unkeyedContainer()
      if let count = container.count {
        elements.reserveCapacity(count)
      }
      while !container.isAtEnd {
        try elements.insert(
          Element(
            tag: container.decode(String.self),
            item: container.decode(String.self)
          ),
          at: 0
        )
      }
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.unkeyedContainer()
      for element in elements.reversed() {
        try container.encode(element.tag)
        try container.encode(element.item)
      }
    }
  }
}