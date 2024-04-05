#if canImport(SwiftUI)
  import SwiftUI

  extension Binding {
    /// Creates a binding by projecting the current optional value to a boolean describing if it's
    /// non-`nil`.
    ///
    /// Writing `false` to the binding will `nil` out the base value. Writing `true` does nothing.
    ///
    /// - Returns: A binding to a boolean. Returns `true` if non-`nil`, otherwise `false`.
    public func isPresent<Wrapped>() -> Binding<Bool>
    where Value == Wrapped? {
      self._isPresent
    }
  }

  extension Optional {
    fileprivate var _isPresent: Bool {
      get { self != nil }
      set {
        guard !newValue else { return }
        self = nil
      }
    }
  }

#endif
