#if canImport(SwiftUI)
  import SwiftUI

  extension Binding {
    /// Creates a binding by projecting the base optional value to a Boolean value.
    ///
    /// Writing `false` to the binding will `nil` out the base value. Writing `true` does nothing.
    ///
    /// - Parameter base: A value to project to a Boolean value.
    public init<V>(_ base: Binding<V?>) where Value == Bool {
      self = base._isPresent
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
