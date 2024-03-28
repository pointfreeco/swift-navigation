#if canImport(SwiftUI)
  import SwiftUI

  // MARK: - Alert with dynamic title
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
    /// See <doc:Dialogs> for more information on how to use this API.
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
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Item, A: View, M: View>(
      item: Binding<Item?>,
      title: (Item) -> Text,
      @ViewBuilder actions: (Item) -> A,
      @ViewBuilder message: (Item) -> M
    ) -> some View {
      alert(
        item.wrappedValue.map(title) ?? Text(verbatim: ""),
        isPresented: item.isPresent(),
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
    /// See <doc:Dialogs> for more information on how to use this API.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional value that determines whether an alert should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and passed
    ///     to the modifier's closures. You can use this data to populate the fields of an alert
    ///     that the system displays to the user. When the user presses or taps one of the alert's
    ///     actions, the system sets this value to `nil` and dismisses the alert.
    ///   - title: A closure returning the alert's title given the current alert state.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Item, A: View>(
      item: Binding<Item?>,
      title: (Item) -> Text,
      @ViewBuilder actions: (Item) -> A
    ) -> some View {
      alert(
        item.wrappedValue.map(title) ?? Text(verbatim: ""),
        isPresented: item.isPresent(),
        presenting: item.wrappedValue,
        actions: actions
      )
    }
  }

  // MARK: - Alert with static localized title

  extension View {
    /// Presents an alert from a binding to an optional value with a static title.
    ///
    /// This function is similar to the other `alert` overload, but it takes a `LocalizedStringKey` for
    /// a static title instead of a dynamic one. This is useful when the title of the alert does not
    /// depend on the item that is being presented.
    ///
    /// The alert is presented when the `item` binding is non-`nil`. The `actions` and `message`
    /// closures receive the unwrapped item to customize the alert's actions and message. When the user
    /// dismisses the alert by tapping one of its actions, the system sets the `item` binding to `nil`.
    ///
    /// Usage example:
    ///
    /// ```swift
    /// struct AlertDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .alert("Random Movie", item: self.$randomMovie) { _ in
    ///          Button("Pick another", action: self.getRandomMovie)
    ///          Button("I'm done", action: self.clearRandomMovie)
    ///        } message: {
    ///          Text($0.summary)
    ///        }
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
    ///   - titleKey: A `LocalizedStringKey` representing the static title of the alert.
    ///   - item: A binding to an optional value that determines whether an alert should be presented.
    ///     When the binding is updated with a non-`nil` value, it is unwrapped and passed to the
    ///     modifier's closures. You can use this data to populate the fields of an alert that the
    ///     system displays to the user. When the user presses or taps one of the alert's actions, the
    ///     system sets this value to `nil` and dismisses the alert.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    ///   - message: A view builder returning the message for the alert given the current alert state.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Item, A: View, M: View>(
      _ titleKey: LocalizedStringKey,
      item: Binding<Item?>,
      @ViewBuilder actions: (Item) -> A,
      @ViewBuilder message: (Item) -> M
    ) -> some View {
      alert(
        item: item,
        title: { _ in Text(titleKey) },
        actions: actions,
        message: message
      )
    }

    /// Presents an alert from a binding to an optional value with a static title.
    ///
    /// This function is similar to the other `alert` overload, but it takes a `LocalizedStringKey` for
    /// a static title instead of a dynamic one. This is useful when the title of the alert does not
    /// depend on the item that is being presented.
    ///
    /// The alert is presented when the `item` binding is non-`nil`. The `actions` closure receives the
    /// unwrapped item to customize the alert's actions and message. When the user
    /// dismisses the alert by tapping one of its actions, the system sets the `item` binding to `nil`.
    ///
    /// Usage example:
    ///
    /// ```swift
    /// struct AlertDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .alert("Random Movie", item: self.$randomMovie) { _ in
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
    ///   - titleKey: A `LocalizedStringKey` representing the static title of the alert.
    ///   - item: A binding to an optional value that determines whether an alert should be presented.
    ///     When the binding is updated with a non-`nil` value, it is unwrapped and passed to the
    ///     modifier's closures. You can use this data to populate the fields of an alert that the
    ///     system displays to the user. When the user presses or taps one of the alert's actions, the
    ///     system sets this value to `nil` and dismisses the alert.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Item, A: View>(
      _ titleKey: LocalizedStringKey,
      item: Binding<Item?>,
      @ViewBuilder actions: (Item) -> A
    ) -> some View {
      alert(
        item: item,
        title: { _ in Text(titleKey) },
        actions: actions
      )
    }
  }

  // MARK: - Alert with static title

  extension View {
    // Variation of the previous one, with a `_ title: String` instead of a `LocalizedStringKey`:

    /// Presents an alert from a binding to an optional value with a static title.
    /// 
    /// This function is similar to the other `alert` overload, but it takes a `String` for a static
    /// title instead of a dynamic one. This is useful when the title of the alert does not depend on
    /// the item that is being presented.
    ///
    /// The alert is presented when the `item` binding is non-`nil`. The `actions` and `message`
    /// closures receive the unwrapped item to customize the alert's actions and message. When the user
    /// dismisses the alert by tapping one of its actions, the system sets the `item` binding to `nil`.
    ///
    /// Usage example:
    ///
    /// ```swift
    /// struct AlertDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .alert("Random Movie", item: self.$randomMovie) { _ in
    ///           Button("Pick another", action: self.getRandomMovie)
    ///           Button("I'm done", action: self.clearRandomMovie)
    ///         } message: {
    ///           Text($0.summary)
    ///         }
    ///       )
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
    ///   - title: A `String` representing the static title of the alert.
    ///   - item: A binding to an optional value that determines whether an alert should be presented.
    ///     When the binding is updated with a non-`nil` value, it is unwrapped and passed to the
    ///     modifier's closures. You can use this data to populate the fields of an alert that the
    ///     system displays to the user. When the user presses or taps one of the alert's actions, the
    ///     system sets this value to `nil` and dismisses the alert.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    ///   - message: A view builder returning the message for the alert given the current alert state.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Item, A: View, M: View>(
      _ title: String,
      item: Binding<Item?>,
      @ViewBuilder actions: (Item) -> A,
      @ViewBuilder message: (Item) -> M
    ) -> some View {
      alert(
        item: item,
        title: { _ in Text(title) },
        actions: actions,
        message: message
      )
    }

    /// Presents an alert from a binding to an optional value with a static title.
    ///
    /// This function is similar to the other `alert` overload, but it takes a `String` for a static
    /// title instead of a dynamic one. This is useful when the title of the alert does not depend on
    /// the item that is being presented.
    ///
    /// The alert is presented when the `item` binding is non-`nil`. The `actions` closure receives the
    /// unwrapped item to customize the alert's actions and message. When the user
    /// dismisses the alert by tapping one of its actions, the system sets the `item` binding to `nil`.
    ///
    /// Usage example:
    ///
    /// ```swift
    /// struct AlertDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .alert("Random Movie", item: self.$randomMovie) { _ in
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
    ///   - title: A `String` representing the static title of the alert.
    ///   - item: A binding to an optional value that determines whether an alert should be presented.
    ///     When the binding is updated with a non-`nil` value, it is unwrapped and passed to the
    ///     modifier's closures. You can use this data to populate the fields of an alert that the
    ///     system displays to the user. When the user presses or taps one of the alert's actions, the
    ///     system sets this value to `nil` and dismisses the alert.
    ///   - actions: A view builder returning the alert's actions given the current alert state.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func alert<Item, A: View>(
      _ title: String,
      item: Binding<Item?>,
      @ViewBuilder actions: (Item) -> A
    ) -> some View {
      alert(
        item: item,
        title: { _ in Text(title) },
        actions: actions
      )
    }
  }
#endif
