import SwiftUI

extension Binding where Value == Bool {
  func resignFirstResponder() -> Self {
    Self(
      get: { self.wrappedValue },
      set: { newValue, transaction in
        if self.wrappedValue, !newValue {
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
          )
        }
        self.transaction(transaction).wrappedValue = newValue
      }
    )
  }
}
