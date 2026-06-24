#if canImport(SwiftUI)
  public import SwiftUI

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    /// Presents a confirmation dialog from a binding to an optional value.
    ///
    /// SwiftUI's `confirmationDialog` view modifiers are driven by two disconnected pieces of
    /// state: an `isPresented` binding to a boolean that determines if the dialog should be
    /// presented, and optional dialog `data` that is used to customize its actions and message.
    ///
    /// Modeling the domain in this way unfortunately introduces a couple invalid runtime states:
    ///
    ///   * `isPresented` can be `true`, but `data` can be `nil`.
    ///   * `isPresented` can be `false`, but `data` can be non-`nil`.
    ///
    /// On top of that, SwiftUI's `confirmationDialog` modifiers take static titles, which means the
    /// title cannot be dynamically computed from the dialog data.
    ///
    /// This overload addresses these shortcomings with a streamlined API. First, it eliminates the
    /// invalid runtime states at compile time by driving the dialog's presentation from a single,
    /// optional binding. When this binding is non-`nil`, the dialog will be presented. Further, the
    /// title can be customized from the dialog data.
    ///
    /// ```swift
    /// struct DialogDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .confirmationDialog(item: self.$randomMovie, titleVisibility: .always) {
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
    ///   - item: A binding to an optional value that determines whether a dialog should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and passed
    ///     to the modifier's closures. You can use this data to populate the fields of a dialog
    ///     that the system displays to the user. When the user presses or taps one of the dialog's
    ///     actions, the system sets this value to `nil` and dismisses the dialog.
    ///   - title: A closure returning the dialog's title given the current dialog state.
    ///   - titleVisibility: The visibility of the dialog's title. (default: .automatic)
    ///   - actions: A view builder returning the dialog's actions given the current dialog state.
    ///   - message: A view builder returning the message for the dialog given the current dialog
    ///     state.
    public func confirmationDialog<Item, A: View, M: View>(
      item: Binding<Item?>,
      titleVisibility: Visibility = .automatic,
      title: (Item) -> Text,
      @ViewBuilder actions: (Item) -> A,
      @ViewBuilder message: (Item) -> M
    ) -> some View {
      modifier(
        ConfirmationDialogModifier(
          item: item,
          titleVisibility: titleVisibility,
          title: title,
          actions: actions,
          message: message
        )
      )
    }

    /// Presents a confirmation dialog from a binding to an optional value.
    ///
    /// SwiftUI's `confirmationDialog` view modifiers are driven by two disconnected pieces of
    /// state: an `isPresented` binding to a boolean that determines if the dialog should be
    /// presented, and optional dialog `data` that is used to customize its actions and message.
    ///
    /// Modeling the domain in this way unfortunately introduces a couple invalid runtime states:
    ///
    ///   * `isPresented` can be `true`, but `data` can be `nil`.
    ///   * `isPresented` can be `false`, but `data` can be non-`nil`.
    ///
    /// On top of that, SwiftUI's `confirmationDialog` modifiers take static titles, which means the
    /// title cannot be dynamically computed from the dialog data.
    ///
    /// This overload addresses these shortcomings with a streamlined API. First, it eliminates the
    /// invalid runtime states at compile time by driving the dialog's presentation from a single,
    /// optional binding. When this binding is non-`nil`, the dialog will be presented. Further, the
    /// title can be customized from the dialog data.
    ///
    /// ```swift
    /// struct DialogDemo: View {
    ///   @State var randomMovie: Movie?
    ///
    ///   var body: some View {
    ///     Button("Pick a random movie", action: self.getRandomMovie)
    ///       .confirmationDialog(item: self.$randomMovie, titleVisibility: .always) {
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
    ///   - item: A binding to an optional value that determines whether a dialog should be
    ///     presented. When the binding is updated with non-`nil` value, it is unwrapped and passed
    ///     to the modifier's closures. You can use this data to populate the fields of a dialog
    ///     that the system displays to the user. When the user presses or taps one of the dialog's
    ///     actions, the system sets this value to `nil` and dismisses the dialog.
    ///   - title: A closure returning the dialog's title given the current dialog state.
    ///   - titleVisibility: The visibility of the dialog's title. (default: .automatic)
    ///   - actions: A view builder returning the dialog's actions given the current dialog state.
    public func confirmationDialog<Item, A: View>(
      item: Binding<Item?>,
      titleVisibility: Visibility = .automatic,
      title: (Item) -> Text,
      @ViewBuilder actions: (Item) -> A
    ) -> some View {
      modifier(
        ConfirmationDialogModifier(
          item: item,
          titleVisibility: titleVisibility,
          title: title,
          actions: actions,
          message: { _ in }
        )
      )
    }
  }

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  private struct ConfirmationDialogModifier<Item, Actions: View, Message: View>: ViewModifier {
    @Binding var item: Item?
    var titleVisibility: Visibility
    var title: Text
    var actions: Actions?
    var message: Message?
    @Binding private var isPresented: Bool

    init(
      item: Binding<Item?>,
      titleVisibility: Visibility,
      title: (Item) -> Text,
      @ViewBuilder actions: (Item) -> Actions,
      @ViewBuilder message: (Item) -> Message
    ) {
      self._item = item
      self.titleVisibility = titleVisibility
      self.title = item.wrappedValue.map(title) ?? Text(verbatim: "")
      self.actions = item.wrappedValue.map(actions)
      self.message = item.wrappedValue.map(message)
      self._isPresented = Binding(item)
    }

    func body(content: Content) -> some View {
      let id = (item as? any Identifiable)?.id as? AnyHashable
      content
        .confirmationDialog(
          title,
          isPresented: $isPresented,
          titleVisibility: titleVisibility,
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
