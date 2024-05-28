#if canImport(SwiftUI)
  import SwiftUI

  extension View {
    /// Presents a confirmation dialog from a binding to optional confirmation dialog state.
    ///
    /// See <doc:AlertsDialogs> for more information on how to use this API.
    ///
    /// - Parameters:
    ///   - state: A binding to optional state that determines whether a confirmation dialog should
    ///     be presented. When the binding is updated with non-`nil` value, it is unwrapped and used
    ///     to populate the fields of a dialog that the system displays to the user. When the user
    ///     presses or taps one of the dialog's actions, the system sets this value to `nil` and
    ///     dismisses the dialog, and the action is fed to the `action` closure.
    ///   - handler: A closure that is called with an action from a particular dialog button when
    ///     tapped.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func confirmationDialog<Value>(
      _ state: Binding<ConfirmationDialogState<Value>?>,
      action handler: @escaping (Value?) -> Void = { (_: Never?) in }
    ) -> some View {
      confirmationDialog(
        item: state,
        titleVisibility: state.wrappedValue.map { .init($0.titleVisibility) } ?? .automatic
      ) {
        Text($0.title)
      } actions: {
        ForEach($0.buttons) {
          Button($0, action: handler)
        }
      } message: {
        $0.message.map(Text.init)
      }
    }

    /// Presents a confirmation dialog from a binding to optional confirmation dialog state.
    ///
    /// See <doc:AlertsDialogs> for more information on how to use this API.
    ///
    /// > Warning: Async closures cannot be performed with animation. If the underlying action is
    /// > animated, a runtime warning will be emitted.
    ///
    /// - Parameters:
    ///   - state: A binding to optional state that determines whether a confirmation dialog should
    ///     be presented. When the binding is updated with non-`nil` value, it is unwrapped and used
    ///     to populate the fields of a dialog that the system displays to the user. When the user
    ///     presses or taps one of the dialog's actions, the system sets this value to `nil` and
    ///     dismisses the dialog, and the action is fed to the `action` closure.
    ///   - handler: A closure that is called with an action from a particular dialog button when
    ///     tapped.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func confirmationDialog<Value>(
      _ state: Binding<ConfirmationDialogState<Value>?>,
      action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
    ) -> some View {
      confirmationDialog(
        item: state,
        titleVisibility: state.wrappedValue.map { .init($0.titleVisibility) } ?? .automatic
      ) {
        Text($0.title)
      } actions: {
        ForEach($0.buttons) {
          Button($0, action: handler)
        }
      } message: {
        $0.message.map(Text.init)
      }
    }
  }
#endif  // canImport(SwiftUI)
