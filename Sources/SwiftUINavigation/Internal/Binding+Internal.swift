#if canImport(SwiftUI)
  import SwiftUI

  extension Binding {
    func didSet(_ perform: @escaping (Value) -> Void) -> Self {
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
