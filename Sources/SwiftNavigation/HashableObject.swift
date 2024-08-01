/// A protocol that adds a default implementation of `Hashable` to an object based off its object
/// identity.
///
/// SwiftUI's navigation tools requires `Identifiable` and `Hashable` conformances throughout its
/// APIs, for example `sheet(item:)` requires `Identifiable`, while `navigationDestination(item:)`
/// and `NavigationLink.init(value:)` require `Hashable`. While `Identifiable` conformances come for
/// free on objects based on object identity, there is no such mechanism for `Hashable`. This
/// protocol addresses this shortcoming by providing default implementations of `==` and
/// `hash(into:)`.
public protocol HashableObject: AnyObject, Hashable {}

extension HashableObject {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
