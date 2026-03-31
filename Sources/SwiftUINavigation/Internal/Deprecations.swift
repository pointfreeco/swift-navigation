import SwiftUI

// NB: Deprecated after 2.7.0

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
@available(*, deprecated, message: "Provide an explicit action handler")
extension View {
  #if compiler(>=6)
    @MainActor
  #endif
  public func alert<Value>(_ state: Binding<AlertState<Value>?>) -> some View {
    alert(state) { _ in }
  }

  public func confirmationDialog<Value>(
    _ state: Binding<ConfirmationDialogState<Value>?>,
  ) -> some View {
    confirmationDialog(state) { _ in }
  }
}
