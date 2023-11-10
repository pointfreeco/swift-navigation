#if canImport(SwiftUI)
  import CustomDump
  import SwiftUI

  /// A data type that describes the state of a confirmation dialog that can be shown to the user. The
  /// `Action` generic is the type of actions that can be sent from tapping on a button in the sheet.
  ///
  /// This type can be used in your application's state in order to control the presentation and
  /// actions of dialogs. This API can be used to push the logic of alert presentation and action into
  /// your model, making it easier to test, and simplifying your view layer.
  ///
  /// To use this API, you describe all of a dialog's actions as cases in an enum:
  ///
  /// ```swift
  /// @Observable
  /// class FeatureModel {
  ///   enum ConfirmationDialogAction {
  ///     case delete
  ///     case favorite
  ///   }
  ///   // ...
  /// }
  /// ```
  ///
  /// You model the state for showing the alert in as a published field, which can start off `nil`:
  ///
  /// ```swift
  /// @Observable
  /// class FeatureModel {
  ///   // ...
  ///   var dialog: ConfirmationDialogState<ConfirmationDialogAction>?
  ///   // ...
  /// }
  /// ```
  ///
  /// And you define an endpoint for handling each alert action:
  ///
  /// ```swift
  /// @Observable
  /// class FeatureModel {
  ///   // ...
  ///   func dialogButtonTapped(_ action: ConfirmationDialogAction) {
  ///     switch action {
  ///     case .delete:
  ///       // ...
  ///     case .favorite:
  ///       // ...
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Then, in an endpoint that should display an alert, you can construct a
  /// ``ConfirmationDialogState`` value to represent it:
  ///
  /// ```swift
  /// @Observable
  /// class FeatureModel {
  ///   // ...
  ///   func infoButtonTapped() {
  ///     self.dialog = ConfirmationDialogState(
  ///       title: "What would you like to do?",
  ///       buttons: [
  ///         .default(TextState("Favorite"), action: .send(.favorite)),
  ///         .destructive(TextState("Delete"), action: .send(.delete)),
  ///         .cancel(TextState("Cancel")),
  ///       ]
  ///     )
  ///   }
  /// }
  /// ```
  ///
  /// And in your view you can use the `.confirmationDialog(unwrapping:action:)` view modifier to
  /// present the dialog:
  ///
  /// ```swift
  /// struct ItemView: View {
  ///   @ObservedObject var model: FeatureModel
  ///
  ///   var body: some View {
  ///     VStack {
  ///       Button("Info") {
  ///         self.model.infoButtonTapped()
  ///       }
  ///     }
  ///     .confirmationDialog(unwrapping: self.$model.dialog) { action in
  ///       self.model.dialogButtonTapped(action)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// This makes your model in complete control of when the alert is shown or dismissed, and makes it
  /// so that any choice made in the alert is automatically fed back into the model so that you can
  /// handle its logic.
  ///
  /// Even better, you can instantly write tests that your alert behavior works as expected:
  ///
  /// ```swift
  /// let model = FeatureModel()
  ///
  /// model.infoButtonTapped()
  /// XCTAssertEqual(
  ///   model.dialog,
  ///   ConfirmationDialogState(
  ///     title: "What would you like to do?",
  ///     buttons: [
  ///       .default(TextState("Favorite"), action: .send(.favorite)),
  ///       .destructive(TextState("Delete"), action: .send(.delete)),
  ///       .cancel(TextState("Cancel")),
  ///     ]
  ///   )
  /// )
  ///
  /// model.dialogButtonTapped(.favorite)
  /// // Verify that favorite logic executed correctly
  /// model.dialog = nil
  /// ```
  @available(iOS 13, *)
  @available(macOS 12, *)
  @available(tvOS 13, *)
  @available(watchOS 6, *)
  public struct ConfirmationDialogState<Action>: Identifiable {
    public let id: UUID
    public var buttons: [ButtonState<Action>]
    public var message: TextState?
    public var title: TextState
    public var titleVisibility: ConfirmationDialogStateTitleVisibility

    init(
      id: UUID,
      buttons: [ButtonState<Action>],
      message: TextState?,
      title: TextState,
      titleVisibility: ConfirmationDialogStateTitleVisibility
    ) {
      self.id = id
      self.buttons = buttons
      self.message = message
      self.title = title
      self.titleVisibility = titleVisibility
    }

    /// Creates confirmation dialog state.
    ///
    /// - Parameters:
    ///   - titleVisibility: The visibility of the dialog's title.
    ///   - title: The title of the dialog.
    ///   - actions: A ``ButtonStateBuilder`` returning the dialog's actions.
    ///   - message: The message for the dialog.
    @available(iOS 15, *)
    @available(macOS 12, *)
    @available(tvOS 15, *)
    @available(watchOS 8, *)
    public init(
      titleVisibility: ConfirmationDialogStateTitleVisibility,
      title: () -> TextState,
      @ButtonStateBuilder<Action> actions: () -> [ButtonState<Action>] = { [] },
      message: (() -> TextState)? = nil
    ) {
      self.init(
        id: UUID(),
        buttons: actions(),
        message: message?(),
        title: title(),
        titleVisibility: titleVisibility
      )
    }

    /// Creates confirmation dialog state.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - actions: A ``ButtonStateBuilder`` returning the dialog's actions.
    ///   - message: The message for the dialog.
    public init(
      title: () -> TextState,
      @ButtonStateBuilder<Action> actions: () -> [ButtonState<Action>] = { [] },
      message: (() -> TextState)? = nil
    ) {
      self.init(
        id: UUID(),
        buttons: actions(),
        message: message?(),
        title: title(),
        titleVisibility: .automatic
      )
    }

    public func map<NewAction>(
      _ transform: (Action?) -> NewAction?
    ) -> ConfirmationDialogState<NewAction> {
      ConfirmationDialogState<NewAction>(
        id: self.id,
        buttons: self.buttons.map { $0.map(transform) },
        message: self.message,
        title: self.title,
        titleVisibility: self.titleVisibility
      )
    }
  }

  /// The visibility of a confirmation dialog title element, chosen automatically based on the
  /// platform, current context, and other factors.
  ///
  /// See `SwiftUI.Visibility` for more information.
  public enum ConfirmationDialogStateTitleVisibility: Sendable {
    /// The element may be visible or hidden depending on the policies of the component accepting the
    /// visibility configuration.
    ///
    /// See `SwiftUI.Visibility.automatic` for more information.
    case automatic

    /// The element may be hidden.
    ///
    /// See `SwiftUI.Visibility.hidden` for more information.
    case hidden
    /// The element may be visible.
    ///
    /// See `SwiftUI.Visibility.visible` for more information.
    case visible
  }

  @available(iOS 13, *)
  @available(macOS 12, *)
  @available(tvOS 13, *)
  @available(watchOS 6, *)
  extension ConfirmationDialogState: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
      var children: [(label: String?, value: Any)] = []
      if self.titleVisibility != .automatic {
        children.append(("titleVisibility", self.titleVisibility))
      }
      children.append(("title", self.title))
      if !self.buttons.isEmpty {
        children.append(("actions", self.buttons))
      }
      if let message = self.message {
        children.append(("message", message))
      }
      return Mirror(
        self,
        children: children,
        displayStyle: .struct
      )
    }
  }

  @available(iOS 13, *)
  @available(macOS 12, *)
  @available(tvOS 13, *)
  @available(watchOS 6, *)
  extension ConfirmationDialogState: Equatable where Action: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.title == rhs.title
        && lhs.message == rhs.message
        && lhs.buttons == rhs.buttons
    }
  }

  @available(iOS 13, *)
  @available(macOS 12, *)
  @available(tvOS 13, *)
  @available(watchOS 6, *)
  extension ConfirmationDialogState: Hashable where Action: Hashable {
    public func hash(into hasher: inout Hasher) {
      hasher.combine(self.title)
      hasher.combine(self.message)
      hasher.combine(self.buttons)
    }
  }

  @available(iOS 13, *)
  @available(macOS 12, *)
  @available(tvOS 13, *)
  @available(watchOS 6, *)
  extension ConfirmationDialogState: Sendable where Action: Sendable {}

  // MARK: - SwiftUI bridging

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
      }
    }
  }
#endif  // canImport(SwiftUI)
