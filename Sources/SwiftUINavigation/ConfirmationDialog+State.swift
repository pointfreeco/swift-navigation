#if canImport(SwiftUI)
  public import SwiftNavigation
  public import SwiftUI

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension Visibility {
    public init(_ visibility: ConfirmationDialogStateTitleVisibility) {
      switch visibility {
      case .automatic:
        self = .automatic
      case .hidden:
        self = .hidden
      case .visible:
        self = .visible
      @unknown default:
        self = .automatic
      }
    }
  }

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    /// Presents a confirmation dialog from a binding to optional confirmation dialog state.
    ///
    /// See <doc:AlertsDialogs> for more information on how to use this API.
    ///
    /// - Parameter state: A binding to optional state that determines whether a confirmation dialog
    ///   should be presented. When the binding is updated with non-`nil` value, it is unwrapped and
    ///   used to populate the fields of a dialog that the system displays to the user. When the
    ///   user presses or taps one of the dialog's actions, the system sets this value to `nil` and
    ///   dismisses the dialog, and the action is fed to the `action` closure.
    public func confirmationDialog(
      _ state: Binding<ConfirmationDialogState<Never>?>,
    ) -> some View {
      confirmationDialog(state) { _ in }
    }

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
    public func confirmationDialog<Value>(
      _ state: Binding<ConfirmationDialogState<Value>?>,
      action handler: @escaping (Value?) -> Void
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
    public func confirmationDialog<Value: Sendable>(
      _ state: Binding<ConfirmationDialogState<Value>?>,
      action handler: @escaping @Sendable (Value?) async -> Void
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

  @available(
    iOS,
    introduced: 13,
    deprecated: 100000,
    message:
      "use 'View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)' instead."
  )
  @available(
    macOS,
    introduced: 12,
    unavailable
  )
  @available(
    tvOS,
    introduced: 13,
    deprecated: 100000,
    message:
      "use 'View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)' instead."
  )
  @available(
    watchOS,
    introduced: 6,
    deprecated: 100000,
    message:
      "use 'View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)' instead."
  )
  extension ActionSheet {
    public init<Action>(
      _ state: ConfirmationDialogState<Action>,
      action: @escaping (Action?) -> Void
    ) {
      self.init(
        title: Text(state.title),
        message: state.message.map { Text($0) },
        buttons: state.buttons.map { .init($0, action: action) }
      )
    }
  }
#endif
