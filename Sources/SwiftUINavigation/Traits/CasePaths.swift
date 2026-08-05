#if canImport(SwiftUI) && CasePaths
  public import CasePaths
  import SwiftNavigation
  public import SwiftUI

  extension Binding {
    /// Returns a binding to the associated value of a given case key path.
    ///
    /// Useful for producing bindings to values held in enum state.
    ///
    /// - Parameter keyPath: A case key path to a specific associated value.
    /// - Returns: A new binding.
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
    ) -> Binding<Member>?
    where Value: CasePathable {
      Binding<Member>(unwrapping: self[keyPath])
    }

    /// Returns a binding to the associated value of a given case key path.
    ///
    /// Useful for driving navigation off an optional enumeration of destinations.
    ///
    /// - Parameter keyPath: A case key path to a specific associated value.
    /// - Returns: A new binding.
    public subscript<Enum: CasePathable, Member>(
      dynamicMember keyPath: KeyPath<Enum.AllCasePaths, AnyCasePath<Enum, Member>>
    ) -> Binding<Member?>
    where Value == Enum? {
      self[keyPath]
    }

    /// Returns a binding to a Boolean for a given case key path to a case without an associated
    /// value.
    ///
    /// Useful for driving navigation off an optional enumeration of destinations for navigation
    /// APIs that take a Boolean binding.
    ///
    /// - Parameter keyPath: A case key path to a specific associated value.
    /// - Returns: A new binding.
    public subscript<Enum: CasePathable>(
      dynamicMember keyPath: KeyPath<Enum.AllCasePaths, AnyCasePath<Enum, Void>>
    ) -> Binding<Bool>
    where Value == Enum? {
      Binding<Bool>(self[keyPath])
    }
  }

  extension CasePathable {
    fileprivate subscript<Member>(
      keyPath: KeyPath<Self.AllCasePaths, AnyCasePath<Self, Member>>
    ) -> Member? {
      get {
        Self.allCasePaths[keyPath: keyPath].extract(from: self)
      }
      set {
        guard let newValue else { return }
        self = Self.allCasePaths[keyPath: keyPath].embed(newValue)
      }
    }
  }

  extension Optional where Wrapped: CasePathable {
    fileprivate subscript<Member>(
      keyPath: KeyPath<Wrapped.AllCasePaths, AnyCasePath<Wrapped, Member>>
    ) -> Member? {
      get {
        self.flatMap(Wrapped.allCasePaths[keyPath: keyPath].extract(from:))
      }
      set {
        let casePath = Wrapped.allCasePaths[keyPath: keyPath]
        guard self.flatMap(casePath.extract(from:)) != nil
        else { return }
        self = newValue.map(casePath.embed)
      }
    }
  }
#endif
