import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

extension Binding where Value == Bool {
  @MainActor
  func resignFirstResponder() -> Self {
    Self(
      get: { self.wrappedValue },
      set: { newValue, transaction in
        if self.wrappedValue, !newValue {
          #if canImport(UIKit)
            UIApplication.shared.sendAction(
              #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
          #elseif canImport(AppKit)
            NSApp.sendAction(
              #selector(NSResponder.resignFirstResponder), to: nil, from: nil
            )
          #endif
        }
        self.transaction(transaction).wrappedValue = newValue
      }
    )
  }
}
