#if canImport(SwiftUI)
  import SwiftUI

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
    ///       .alert(
    ///         title: { Text($0.title) },
    ///         unwrapping: self.$randomMovie,
    ///         actions: { _ in
    ///           Button("Pick another", action: self.getRandomMovie)
    ///         },
    ///         message: { Text($0.summary) }
    ///       )
    ///   }
    ///
    ///   func getRandomMovie() {
    ///     self.randomMovie = Movie.allCases.randomElement()
    ///   }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: A closure returning the alert's title given the current alert state.
    ///   - value: A binding to an optional value that determines whether an alert should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and passed
    ///     to the modifier's closures. You can use this data to populate the fields of an alert
    ///     that the system displays to the user. When the user presses or taps one of the alert's
    ///     actions, the system sets this value to `nil` and dismisses the alert.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    ///   - message: A view builder returning the message for the alert given the current alert
    ///     state.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Value, A: View, M: View>(
      title: (Value) -> Text,
      unwrapping value: Binding<Value?>,
      @ViewBuilder actions: (Value) -> A,
      @ViewBuilder message: (Value) -> M
    ) -> some View {
      self.alert(
        value.wrappedValue.map(title) ?? Text(""),
        isPresented: value.isPresent(),
        presenting: value.wrappedValue,
        actions: actions,
        message: message
      )
    }

    /// Presents an alert from a binding to an optional enum, and a [case path][case-paths-gh] to a
    /// specific case.
    ///
    /// A version of `alert(unwrapping:)` that works with enum state.
    ///
    /// [case-paths-gh]: http://github.com/pointfreeco/swift-case-paths
    ///
    /// - Parameters:
    ///   - title: A closure returning the alert's title given the current alert state.
    ///   - enum: A binding to an optional enum that holds alert state at a particular case. When
    ///     the binding is updated with a non-`nil` enum, the case path will attempt to extract this
    ///     state and then pass it to the modifier's closures. You can use it to populate the fields
    ///     of an alert that the system displays to the user. When the user presses or taps one of the
    ///     alert's actions, the system sets this value to `nil` and dismisses the alert.
    ///   - casePath: A case path that identifies a particular case that holds alert state.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    ///   - message: A view builder returning the message for the alert given the current alert
    ///     state.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Enum, Case, A: View, M: View>(
      title: (Case) -> Text,
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, Case>,
      @ViewBuilder actions: (Case) -> A,
      @ViewBuilder message: (Case) -> M
    ) -> some View {
      self.alert(
        title: title,
        unwrapping: `enum`.case(casePath),
        actions: actions,
        message: message
      )
    }

    #if swift(>=5.7)
      /// Presents an alert from a binding to optional ``AlertState``.
      ///
      /// See <doc:AlertsDialogs> for more information on how to use this API.
      ///
      /// - Parameters:
      ///   - value: A binding to an optional value that determines whether an alert should be
      ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and used to
      ///     populate the fields of an alert that the system displays to the user. When the user
      ///     presses or taps one of the alert's actions, the system sets this value to `nil` and
      ///     dismisses the alert, and the action is fed to the `action` closure.
      ///   - handler: A closure that is called with an action from a particular alert button when
      ///     tapped.
      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Value>(
        unwrapping value: Binding<AlertState<Value>?>,
        action handler: @escaping (Value?) -> Void = { (_: Never?) in }
      ) -> some View {
        self.alert(
          (value.wrappedValue?.title).map(Text.init) ?? Text(""),
          isPresented: value.isPresent(),
          presenting: value.wrappedValue,
          actions: {
            ForEach($0.buttons) {
              Button($0, action: handler)
            }
          },
          message: { $0.message.map { Text($0) } }
        )
      }

      /// Presents an alert from a binding to optional ``AlertState``.
      ///
      /// See <doc:AlertsDialogs> for more information on how to use this API.
      ///
      /// > Warning: Async closures cannot be performed with animation. If the underlying action is
      /// > animated, a runtime warning will be emitted.
      ///
      /// - Parameters:
      ///   - value: A binding to an optional value that determines whether an alert should be
      ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and used to
      ///     populate the fields of an alert that the system displays to the user. When the user
      ///     presses or taps one of the alert's actions, the system sets this value to `nil` and
      ///     dismisses the alert, and the action is fed to the `action` closure.
      ///   - handler: A closure that is called with an action from a particular alert button when
      ///     tapped.
      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Value>(
        unwrapping value: Binding<AlertState<Value>?>,
        action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
      ) -> some View {
        self.alert(
          (value.wrappedValue?.title).map(Text.init) ?? Text(""),
          isPresented: value.isPresent(),
          presenting: value.wrappedValue,
          actions: {
            ForEach($0.buttons) {
              Button($0, action: handler)
            }
          },
          message: { $0.message.map { Text($0) } }
        )
      }

      /// Presents an alert from a binding to an optional enum, and a [case path][case-paths-gh] to a
      /// specific case of ``AlertState``.
      ///
      /// A version of `alert(unwrapping:)` that works with enum state. See <doc:AlertsDialogs> for
      /// more information on how to use this API.
      ///
      /// [case-paths-gh]: http://github.com/pointfreeco/swift-case-paths
      ///
      /// - Parameters:
      ///   - enum: A binding to an optional enum that holds alert state at a particular case. When
      ///     the binding is updated with a non-`nil` enum, the case path will attempt to extract this
      ///     state and use it to populate the fields of an alert that the system displays to the user.
      ///     When the user presses or taps one of the alert's actions, the system sets this value to
      ///     `nil` and dismisses the alert, and the action is fed to the `action` closure.
      ///   - casePath: A case path that identifies a particular case that holds alert state.
      ///   - handler: A closure that is called with an action from a particular alert button when
      ///     tapped.
      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, AlertState<Value>>,
        action handler: @escaping (Value?) -> Void = { (_: Never?) in }
      ) -> some View {
        self.alert(unwrapping: `enum`.case(casePath), action: handler)
      }

      /// Presents an alert from a binding to an optional enum, and a [case path][case-paths-gh] to a
      /// specific case of ``AlertState``.
      ///
      /// A version of `alert(unwrapping:)` that works with enum state. See <doc:AlertsDialogs> for
      /// more information on how to use this API.
      ///
      /// > Warning: Async closures cannot be performed with animation. If the underlying action is
      /// > animated, a runtime warning will be emitted.
      ///
      /// [case-paths-gh]: http://github.com/pointfreeco/swift-case-paths
      ///
      /// - Parameters:
      ///   - enum: A binding to an optional enum that holds alert state at a particular case. When
      ///     the binding is updated with a non-`nil` enum, the case path will attempt to extract this
      ///     state and use it to populate the fields of an alert that the system displays to the user.
      ///     When the user presses or taps one of the alert's actions, the system sets this value to
      ///     `nil` and dismisses the alert, and the action is fed to the `action` closure.
      ///   - casePath: A case path that identifies a particular case that holds alert state.
      ///   - handler: A closure that is called with an action from a particular alert button when
      ///     tapped.
      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, AlertState<Value>>,
        action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
      ) -> some View {
        self.alert(unwrapping: `enum`.case(casePath), action: handler)
      }
    #else
      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Value>(
        unwrapping value: Binding<AlertState<Value>?>,
        action handler: @escaping (Value?) -> Void
      ) -> some View {
        self.alert(
          (value.wrappedValue?.title).map(Text.init) ?? Text(""),
          isPresented: value.isPresent(),
          presenting: value.wrappedValue,
          actions: {
            ForEach($0.buttons) {
              Button($0, action: handler)
            }
          },
          message: { $0.message.map { Text($0) } }
        )
      }

      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Value>(
        unwrapping value: Binding<AlertState<Value>?>,
        action handler: @escaping (Value?) async -> Void
      ) -> some View {
        self.alert(
          (value.wrappedValue?.title).map(Text.init) ?? Text(""),
          isPresented: value.isPresent(),
          presenting: value.wrappedValue,
          actions: {
            ForEach($0.buttons) {
              Button($0, action: handler)
            }
          },
          message: { $0.message.map { Text($0) } }
        )
      }

      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert(
        unwrapping value: Binding<AlertState<Never>?>
      ) -> some View {
        self.alert(
          (value.wrappedValue?.title).map(Text.init) ?? Text(""),
          isPresented: value.isPresent(),
          presenting: value.wrappedValue,
          actions: {
            ForEach($0.buttons) {
              Button($0) { _ in }
            }
          },
          message: { $0.message.map { Text($0) } }
        )
      }

      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, AlertState<Value>>,
        action handler: @escaping (Value?) -> Void
      ) -> some View {
        self.alert(unwrapping: `enum`.case(casePath), action: handler)
      }

      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, AlertState<Value>>,
        action handler: @escaping (Value?) async -> Void
      ) -> some View {
        self.alert(unwrapping: `enum`.case(casePath), action: handler)
      }

      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      public func alert<Enum>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, AlertState<Never>>
      ) -> some View {
        self.alert(unwrapping: `enum`.case(casePath)) { (_: Never?) in }
      }
    #endif

    // TODO: support iOS <15?
  }
#endif  // canImport(SwiftUI)
