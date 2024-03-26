#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension Binding {
    /// Creates a binding by projecting the current optional value to a boolean describing if it's
    /// non-`nil`.
    ///
    /// Writing `false` to the binding will `nil` out the base value. Writing `true` does nothing.
    ///
    /// - Returns: A binding to a boolean. Returns `true` if non-`nil`, otherwise `false`.
    public func isPresent<Wrapped>() -> Binding<Bool>
      where Value == Wrapped? {
      .init(
        get: { self.wrappedValue != nil },
        set: { isPresent, transaction in
          guard isPresent else { return }
          self.transaction(transaction).wrappedValue = nil
        }
      )
    }
  }
#endif
