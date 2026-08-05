#if canImport(SwiftUI)
  public import SwiftNavigation
  public import SwiftUI

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    /// Presents an alert from a binding to optional alert state.
    ///
    /// See <doc:AlertsDialogs> for more information on how to use this API.
    ///
    /// - Parameter state: A binding to optional alert state that determines whether an alert should
    ///   be presented. When the binding is updated with non-`nil` value, it is unwrapped and used
    ///   to populate the fields of an alert that the system displays to the user. When the user
    ///   presses or taps one of the alert's actions, the system sets this value to `nil` and
    ///   dismisses the alert, and the action is fed to the `action` closure.
    #if compiler(>=6)
      @MainActor
    #endif
    public func alert(_ state: Binding<AlertState<Never>?>) -> some View {
      alert(state) { _ in }
    }

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
    #if compiler(>=6)
      @MainActor
    #endif
    public func alert<Value>(
      _ state: Binding<AlertState<Value>?>,
      action handler: @escaping (Value?) -> Void
    ) -> some View {
      alert(item: state) {
        Text($0.title)
      } actions: {
        ForEach($0.buttons) {
          Button($0, action: handler)
        }
      } message: {
        $0.message.map(Text.init)
      }
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
    public func alert<Value: Sendable>(
      _ state: Binding<AlertState<Value>?>,
      action handler: @escaping @Sendable (Value?) async -> Void
    ) -> some View {
      alert(item: state) {
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
    message: "use 'View.alert(_:action:)' instead."
  )
  @available(
    macOS,
    introduced: 10.15,
    deprecated: 100000,
    message: "use 'View.alert(_:action:)' instead."
  )
  @available(
    tvOS,
    introduced: 13,
    deprecated: 100000,
    message: "use 'View.alert(_:action:)' instead."
  )
  @available(
    watchOS,
    introduced: 6,
    deprecated: 100000,
    message: "use 'View.alert(_:action:)' instead."
  )
  extension Alert {
    /// Creates an alert from alert state.
    ///
    /// - Parameters:
    ///   - state: Alert state used to populate the alert.
    ///   - action: An action handler, called when a button with an action is tapped, by passing the
    ///     action to the closure.
    public init<Action>(_ state: AlertState<Action>, action: @escaping (Action?) -> Void) {
      if state.buttons.count <= 1 {
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          dismissButton: state.buttons.first.map { .init($0, action: action) }
        )
      } else {
        if state.buttons.count > 2 {
          reportIssue(
            """
            'Alert' handed 'AlertState' with too many buttons. Will only display the first two.
            """
          )
        }
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          primaryButton: .init(state.buttons[0], action: action),
          secondaryButton: .init(state.buttons[1], action: action)
        )
      }
    }

    /// Creates an alert from alert state.
    ///
    /// - Parameters:
    ///   - state: Alert state used to populate the alert.
    ///   - action: An action handler, called when a button with an action is tapped, by passing the
    ///     action to the closure.
    public init<Action: Sendable>(
      _ state: AlertState<Action>,
      action: @escaping @Sendable (Action?) async -> Void
    ) {
      if state.buttons.count <= 1 {
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          dismissButton: state.buttons.first.map { .init($0, action: action) }
        )
      } else {
        if state.buttons.count > 2 {
          reportIssue(
            """
            'Alert' handed 'AlertState' with too many buttons. Will only display the first two.
            """
          )
        }
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          primaryButton: .init(state.buttons[0], action: action),
          secondaryButton: .init(state.buttons[1], action: action)
        )
      }
    }
  }
#endif
