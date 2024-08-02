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
    case lazy(Lazy)

    package var element: AnyHashable? {
      switch self {
      case .eager(let element), .lazy(.element(let element)):
        return element
      case .lazy:
        return nil
      }
    }

    public enum Lazy: Equatable {
      case codable(CodableRepresentation.Element)
      case element(AnyHashable)
    }

    package var elementType: Any.Type? {
      switch self {
      case let .eager(value), let .lazy(.element(value)):
        return type(of: value.base)
      case let .lazy(.codable(value)):
        return value.decodableType
      }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case let (.eager(lhs), .eager(rhs)),
        let (.lazy(.element(lhs)), .eager(rhs)),
        let (.lazy(.element(lhs)), .lazy(.element(rhs))),
        let (.eager(lhs), .lazy(.element(rhs))):
        return lhs == rhs
      case let (.lazy(.codable(lhs)), .lazy(.codable(rhs))):
        return lhs == rhs
      case let (.eager(eager), .lazy(.codable(lazy))),
        let (.lazy(.codable(lazy)), .eager(eager)),
        let (.lazy(.element(eager)), .lazy(.codable(lazy))),
        let (.lazy(.codable(lazy)), .lazy(.element(eager))):
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
    self.elements = elements.map { .lazy(.element(AnyHashable($0))) }
  }

  /// Creates a new navigation path from a serializable version.
  ///
  /// - Parameter codable: A value describing the contents of the new path in a serializable format.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public init(_ codable: CodableRepresentation) {
    self.elements = codable.elements.map { .lazy(.codable($0)) }
  }

  /// Appends a new value to the end of this path.
  public mutating func append<V: Hashable>(_ value: V) {
    elements.append(.lazy(.element(value)))
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

      @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
      init?(_ value: AnyHashable) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        func item() -> String? {
          guard let value = value as? any Encodable else { return nil }
          return try? String(decoding: encoder.encode(value), as: UTF8.self)
        }
        guard
          let tag = _mangledTypeName(type(of: value.base)),
          let item = item()
        else { return nil }
        self.init(tag: tag, item: item)
      }

      package func decode() -> AnyHashable? {
        func value(as type: any Decodable.Type) -> AnyHashable? {
          try? JSONDecoder().decode(type, from: Data(item.utf8)) as? AnyHashable
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

    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    fileprivate init?(_ path: UINavigationPath) {
      elements.reserveCapacity(path.elements.count)
      for element in path.elements {
        switch element {
        case let .eager(value),
          let .lazy(.element(value)):
          guard let element = Element(value) else { return nil }
          elements.append(element)
        case let .lazy(.codable(element)):
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
