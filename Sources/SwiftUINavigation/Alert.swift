#if canImport(SwiftUI)
  import IssueReporting
  import SwiftUI

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    /// Presents an alert from a binding to an optional value.
    ///
    /// SwiftUI's `alert` view modifiers are driven by two disconnected pieces of state: an
    /// `isPresented` binding to a boolean that determines if the alert should be presented, and
    /// optional alert `data` that is used to customize its actions and message.
    ///
    /// Modeling the domain in this way unfortunately introduces a couple invalid runtime states:
    ///
    ///   * `isPresented` can be `true`, but `data` can be `nil`.
    ///   * `isPresented` can be `false`, but `data` can be non-`nil`.
    ///
    /// On top of that, SwiftUI's `alert` modifiers take static titles, which means the title cannot
    /// be dynamically computed from the alert data.
    ///
    /// This overload addresses these shortcomings with a streamlined API. First, it eliminates the
    /// invalid runtime states at compile time by driving the alert's presentation from a single,
    /// optional binding. When this binding is non-`nil`, the alert will be presented. Further, the
    /// title can be customized from the alert data.
    ///
    /// ```swift
    /// struct AlertDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .alert(item: self.$randomMovie) {
    ///         Text($0.title)
    ///       } actions: { _ in
    ///         Button("Pick another", action: self.getRandomMovie)
    ///         Button("I'm done", action: self.clearRandomMovie)
    ///       } message: {
    ///         Text($0.summary)
    ///       }
    ///   }
    ///
    ///   func getRandomMovie() {
    ///     self.randomMovie = Movie.allCases.randomElement()
    ///   }
    ///
    ///   func clearRandomMovie() {
    ///     self.randomMovie = nil
    ///   }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - item: A binding to an optional value that determines whether an alert should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and passed
    ///     to the modifier's closures. You can use this data to populate the fields of an alert
    ///     that the system displays to the user. When the user presses or taps one of the alert's
    ///     actions, the system sets this value to `nil` and dismisses the alert.
    ///   - title: A closure returning the alert's title given the current alert state.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    ///   - message: A view builder returning the message for the alert given the current alert
    ///     state.
    public func alert<Item, A: View, M: View>(
      item: Binding<Item?>,
      title: (Item) -> Text,
      @ViewBuilder actions: (Item) -> A,
      @ViewBuilder message: (Item) -> M
    ) -> some View {
      alert(
        item.wrappedValue.map(title) ?? Text(verbatim: ""),
        isPresented: Binding(item),
        presenting: item.wrappedValue,
        actions: actions,
        message: message
      )
    }

    /// Presents an alert from a binding to an optional value.
    ///
    /// SwiftUI's `alert` view modifiers are driven by two disconnected pieces of state: an
    /// `isPresented` binding to a boolean that determines if the alert should be presented, and
    /// optional alert `data` that is used to customize its actions and message.
    ///
    /// Modeling the domain in this way unfortunately introduces a couple invalid runtime states:
    ///  * `isPresented` can be `true`, but `data` can be `nil`.
    ///  * `isPresented` can be `false`, but `data` can be non-`nil`.
    ///
    /// On top of that, SwiftUI's `alert` modifiers take static titles, which means the title cannot
    /// be dynamically computed from the alert data.
    ///
    /// This overload addresses these shortcomings with a streamlined API. First, it eliminates the
    /// invalid runtime states at compile time by driving the alert's presentation from a single,
    /// optional binding. When this binding is non-`nil`, the alert will be presented. Further, the
    /// title can be customized from the alert data.
    ///
    /// ```swift
    /// struct AlertDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .alert(item: self.$randomMovie) {
    ///         Text($0.title)
    ///       } actions: { _ in
    ///         Button("Pick another", action: self.getRandomMovie)
    ///         Button("I'm done", action: self.clearRandomMovie)
    ///       }
    ///   }
    ///
    ///   func getRandomMovie() {
    ///     self.randomMovie = Movie.allCases.randomElement()
    ///   }
    ///
    ///   func clearRandomMovie() {
    ///     self.randomMovie = nil
    ///   }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - item: A binding to an optional value that determines whether an alert should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and passed
    ///     to the modifier's closures. You can use this data to populate the fields of an alert
    ///     that the system displays to the user. When the user presses or taps one of the alert's
    ///     actions, the system sets this value to `nil` and dismisses the alert.
    ///   - title: A closure returning the alert's title given the current alert state.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    public func alert<Item, A: View>(
      item: Binding<Item?>,
      title: (Item) -> Text,
      @ViewBuilder actions: (Item) -> A
    ) -> some View {
      alert(
        item.wrappedValue.map(title) ?? Text(verbatim: ""),
        isPresented: Binding(item),
        presenting: item.wrappedValue,
        actions: actions
      )
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
      action handler: @escaping (Value?) -> Void = { (_: Never?) in }
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
      action handler: @escaping @Sendable (Value?) async -> Void = { (_: Never?) async in }
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
    iOS, introduced: 13, deprecated: 100000, message: "use 'View.alert(_:action:)' instead."
  )
  @available(
    macOS, introduced: 10.15, deprecated: 100000, message: "use 'View.alert(_:action:)' instead."
  )
  @available(
    tvOS, introduced: 13, deprecated: 100000, message: "use 'View.alert(_:action:)' instead."
  )
  @available(
    watchOS, introduced: 6, deprecated: 100000, message: "use 'View.alert(_:action:)' instead."
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
#endif  // canImport(SwiftUI)
