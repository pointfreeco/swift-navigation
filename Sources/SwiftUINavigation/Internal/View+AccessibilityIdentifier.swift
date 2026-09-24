#if canImport(SwiftUI)
  import SwiftUI

  extension View {
    @ViewBuilder
    func accessibilityIdentifier(ifPresent identifier: String?) -> some View {
      if let identifier {
        accessibilityIdentifier(identifier)
      } else {
        self
      }
    }
  }
#endif
