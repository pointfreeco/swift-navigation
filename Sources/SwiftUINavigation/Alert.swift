#if canImport(SwiftUI)
  public import SwiftUI

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
      modifier(
        AlertModifier(
          item: item,
          title: title,
          actions: { actions($0.wrappedValue) },
          message: message
        )
      )
    }

    /// Presents an alert from a binding to an optional value.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional value that determines whether an alert should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and passed
    ///     to the modifier's closures. You can use this data to populate the fields of an alert
    ///     that the system displays to the user. When the user presses or taps one of the alert's
    ///     actions, the system sets this value to `nil` and dismisses the alert.
    ///   - title: A closure returning the alert's title given the current alert state.
    ///   - actions: A view builder returning the alert's actions given a binding to the current
    ///     alert state.
    ///   - message: A view builder returning the message for the alert given the current alert
    ///     state.
    @_disfavoredOverload
    public func alert<Item, A: View, M: View>(
      item: Binding<Item?>,
      title: (Item) -> Text,
      @ViewBuilder actions: (Binding<Item>) -> A,
      @ViewBuilder message: (Item) -> M
    ) -> some View {
      modifier(
        AlertModifier(
          item: item,
          title: title,
          actions: actions,
          message: message
        )
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
      modifier(
        AlertModifier(
          item: item,
          title: title,
          actions: { actions($0.wrappedValue) },
          message: { _ in }
        )
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
    ///   - actions: A view builder returning the alert's actions given a binding to the current
    ///     alert state.
    @_disfavoredOverload
    public func alert<Item, A: View>(
      item: Binding<Item?>,
      title: (Item) -> Text,
      @ViewBuilder actions: (Binding<Item>) -> A
    ) -> some View {
      modifier(
        AlertModifier(
          item: item,
          title: title,
          actions: actions,
          message: { _ in }
        )
      )
    }
  }

  private struct AlertModifier<Item, Actions: View, Message: View>: ViewModifier {
    @Binding var item: Item?
    var title: Text
    var actions: Actions?
    var message: Message?
    @State private var isPresented = false

    init(
      item: Binding<Item?>,
      title: (Item) -> Text,
      @ViewBuilder actions: (Binding<Item>) -> Actions,
      @ViewBuilder message: (Item) -> Message
    ) {
      self._item = item
      self.title = item.wrappedValue.map(title) ?? Text(verbatim: "")
      self.actions = Binding(unwrapping: item).map(actions)
      self.message = item.wrappedValue.map(message)
      self.isPresented = _item.wrappedValue != nil
    }

    func body(content: Content) -> some View {
      let id = (item as? any Identifiable)?.id as? AnyHashable
      content
        .alert(
          title,
          isPresented: $isPresented,
          presenting: item,
          actions: { _ in actions },
          message: { _ in message }
        )
        .onChange(of: id) { [oldValue = id] newValue in
          switch (oldValue, newValue) {
          case (_?, _?):
            isPresented = false
            Task { isPresented = item != nil }
          case (_?, nil), (nil, _?), (nil, nil):
            isPresented = item != nil
          }
        }
    }
  }
#endif
