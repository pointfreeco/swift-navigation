#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

struct AssociatedKeys {
  var keys: [AnyHashableMetatype: UnsafeMutableRawPointer] = [:]

  mutating func key<T>(of type: T.Type) -> UnsafeMutableRawPointer {
    let key = AnyHashableMetatype(type)
    if let associatedKey = keys[key] {
      return associatedKey
    } else {
      let associatedKey = malloc(1)!
      keys[key] = associatedKey
      return associatedKey
    }
  }
}

struct AnyHashableMetatype: Hashable {
  static func == (lhs: AnyHashableMetatype, rhs: AnyHashableMetatype) -> Bool {
    return lhs.base == rhs.base
  }

  let base: Any.Type

  init(_ base: Any.Type) {
    self.base = base
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(base))
  }
}

#endif
