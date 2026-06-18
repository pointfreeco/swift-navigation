public import SwiftNavigation
public import SwiftUI

// NB: Deprecated after 2.7.0

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension View {
  @available(
    *,
    deprecated,
    message: """
      Binding to alert state must not ignore actions; provide an explicit trailing action handler
      """
  )
  #if compiler(>=6)
    @MainActor
  #endif
  public func alert<Value>(_ state: Binding<AlertState<Value>?>) -> some View {
    alert(state) { _ in }
  }

  @available(
    *,
    deprecated,
    message: """
      Binding to confirmation dialog state must not ignore actions; provide an explicit trailing action handler
      """
  )
  public func confirmationDialog<Value>(
    _ state: Binding<ConfirmationDialogState<Value>?>,
  ) -> some View {
    confirmationDialog(state) { _ in }
  }
}
