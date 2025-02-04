#if canImport(SwiftUI)
  import SwiftUI

  extension Binding where Value: Sendable {
    func didSet(_ perform: @escaping @Sendable (Value) -> Void) -> Self {
      .init(
        get: { self.wrappedValue },
        set: { newValue, transaction in
          self.transaction(transaction).wrappedValue = newValue
          perform(newValue)
        }
      )
    }
  }
#endif  // canImport(SwiftUI)
