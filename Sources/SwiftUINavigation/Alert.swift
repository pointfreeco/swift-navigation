#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {

    /// Presents an alert from a binding to optional alert state.
    ///
    /// See <doc:AlertsDialogs> for more information on how to use this API.
    ///
    /// - Parameters:
    ///   - state: A binding to optional alert state that determines whether an alert should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and used to
    ///     populate the fields of an alert that the system displays to the user. When the user
    ///     presses or taps one of the alert's actions, the system sets this value to `nil` and
    ///     dismisses the alert, and the action is fed to the `action` closure.
    ///   - handler: A closure that is called with an action from a particular alert button when
    ///     tapped.
    public func alert<Value>(
      _ state: Binding<AlertState<Value>?>,
      action handler: @escaping (Value?) -> Void = { (_: Never?) in }
    ) -> some View {
      self.alert(
        (state.wrappedValue?.title).map(Text.init) ?? Text(verbatim: ""),
        isPresented: state.isPresent(),
        presenting: state.wrappedValue,
        actions: {
          ForEach($0.buttons) {
            Button($0, action: handler)
          }
        },
        message: { $0.message.map { Text($0) } }
      )
    }

    /// Presents an alert from a binding to optional alert state.
    ///
    /// See <doc:AlertsDialogs> for more information on how to use this API.
    ///
    /// > Warning: Async closures cannot be performed with animation. If the underlying action is
    /// > animated, a runtime warning will be emitted.
    ///
    /// - Parameters:
    ///   - state: A binding to optional alert state that determines whether an alert should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and used to
    ///     populate the fields of an alert that the system displays to the user. When the user
    ///     presses or taps one of the alert's actions, the system sets this value to `nil` and
    ///     dismisses the alert, and the action is fed to the `action` closure.
    ///   - handler: A closure that is called with an action from a particular alert button when
    ///     tapped.
    public func alert<Value>(
      _ state: Binding<AlertState<Value>?>,
      action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
    ) -> some View {
      self.alert(
        (state.wrappedValue?.title).map(Text.init) ?? Text(verbatim: ""),
        isPresented: state.isPresent(),
        presenting: state.wrappedValue,
        actions: {
          ForEach($0.buttons) {
            Button($0, action: handler)
          }
        },
        message: { $0.message.map { Text($0) } }
      )
    }
  }
#endif  // canImport(SwiftUI)
