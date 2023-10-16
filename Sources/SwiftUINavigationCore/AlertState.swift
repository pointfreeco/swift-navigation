#if canImport(SwiftUI)
  import CustomDump
  import SwiftUI

  /// A data type that describes the state of an alert that can be shown to the user. The `Action`
  /// generic is the type of actions that can be sent from tapping on a button in the alert.
  ///
  /// This type can be used in your application's state in order to control the presentation and
  /// actions of alerts. This API can be used to push the logic of alert presentation and actions into
  /// your model, making it easier to test, and simplifying your view layer.
  ///
  /// To use this API, you first describe all of the actions that can take place in all of your
  /// alerts as an enum:
  ///
  /// ```swift
  /// @Observable
  /// class HomeScreenModel {
  ///   enum AlertAction {
  ///     case delete
  ///     case removeFromHomeScreen
  ///   }
  ///   // ...
  /// }
  /// ```
  ///
  /// Then you hold onto optional `AlertState` as a field in your model, which can
  /// start off as `nil`:
  ///
  /// ```swift
  /// @Observable
  /// class HomeScreenModel {
  ///   var alert: AlertState<AlertAction>?
  ///   // ...
  /// }
  /// ```
  ///
  /// And you define an endpoint for handling each alert action:
  ///
  /// ```swift
  /// @Observable
  /// class HomeScreenModel {
  ///   // ...
  ///   func alertButtonTapped(_ action: AlertAction?) {
  ///     switch action {
  ///     case .delete:
  ///       // ...
  ///     case .removeFromHomeScreen:
  ///       // ...
  ///     case .none:
  ///       // ...
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Then, whenever you need to show an alert you can simply construct an ``AlertState`` value to
  /// represent the alert:
  ///
  /// ```swift
  /// @Observable
  /// class HomeScreenModel {
  ///   // ...
  ///   func deleteAppButtonTapped() {
  ///     self.alert = AlertState {
  ///       TextState(#"Remove "Twitter"?"#)
  ///     } actions: {
  ///       ButtonState(role: .destructive, action: .send(.delete)) {
  ///         TextState("Delete App")
  ///       }
  ///       ButtonState(action: .send(.removeFromHomeScreen)) {
  ///         TextState("Remove from Home Screen")
  ///       }
  ///     } message: {
  ///       TextState(
  ///         "Removing from Home Screen will keep the app in your App Library."
  ///       )
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// And in your view you can use the `.alert(unwrapping:action:)` view modifier to present the
  /// alert:
  ///
  /// ```swift
  /// struct FeatureView: View {
  ///   @ObservedObject var model: HomeScreenModel
  ///
  ///   var body: some View {
  ///     VStack {
  ///       Button("Delete") {
  ///         self.model.deleteAppButtonTapped()
  ///       }
  ///     }
  ///     .alert(unwrapping: self.$model.alert) { action in
  ///       self.model.alertButtonTapped(action)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// This makes your model in complete control of when the alert is shown or dismissed, and makes it
  /// so that any choice made in the alert is automatically fed back into the model so that you can
  /// handle its logic.
  ///
  /// Even better, because `AlertState` is equatable (when `Action` is equatable), you can instantly
  /// write tests that your alert behavior works as expected:
  ///
  /// ```swift
  /// let model = HomeScreenModel()
  ///
  /// model.deleteAppButtonTapped()
  /// XCTAssertEqual(
  ///   model.alert,
  ///   AlertState {
  ///     TextState(#"Remove "Twitter"?"#)
  ///   } actions: {
  ///     ButtonState(role: .destructive, action: .deleteButtonTapped) {
  ///       TextState("Delete App"),
  ///     },
  ///     ButtonState(action: .removeFromHomeScreenButtonTapped) {
  ///       TextState("Remove from Home Screen"),
  ///     }
  ///   } message: {
  ///     TextState(
  ///       "Removing from Home Screen will keep the app in your App Library."
  ///     )
  ///   }
  /// )
  ///
  /// model.alertButtonTapped(.delete) {
  ///   // Also verify that delete logic executed correctly
  /// }
  /// model.alert = nil
  /// ```
  public struct AlertState<Action>: Identifiable {
    public let id: UUID
    public var buttons: [ButtonState<Action>]
    public var message: TextState?
    public var title: TextState

    init(
      id: UUID,
      buttons: [ButtonState<Action>],
      message: TextState?,
      title: TextState
    ) {
      self.id = id
      self.buttons = buttons
      self.message = message
      self.title = title
    }

    /// Creates alert state.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - actions: A ``ButtonStateBuilder`` returning the alert's actions.
    ///   - message: The message for the alert.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public init(
      title: () -> TextState,
      @ButtonStateBuilder<Action> actions: () -> [ButtonState<Action>] = { [] },
      message: (() -> TextState)? = nil
    ) {
      self.init(
        id: UUID(),
        buttons: actions(),
        message: message?(),
        title: title()
      )
    }

    public func map<NewAction>(_ transform: (Action?) -> NewAction?) -> AlertState<NewAction> {
      AlertState<NewAction>(
        id: self.id,
        buttons: self.buttons.map { $0.map(transform) },
        message: self.message,
        title: self.title
      )
    }
  }

  extension AlertState: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
      var children: [(label: String?, value: Any)] = [
        ("title", self.title)
      ]
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

  extension AlertState: Equatable where Action: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.title == rhs.title
        && lhs.message == rhs.message
        && lhs.buttons == rhs.buttons
    }
  }

  extension AlertState: Hashable where Action: Hashable {
    public func hash(into hasher: inout Hasher) {
      hasher.combine(self.title)
      hasher.combine(self.message)
      hasher.combine(self.buttons)
    }
  }

  extension AlertState: Sendable where Action: Sendable {}

  // MARK: - SwiftUI bridging

  extension Alert {
    /// Creates an alert from alert state.
    ///
    /// - Parameters:
    ///   - state: Alert state used to populate the alert.
    ///   - action: An action handler, called when a button with an action is tapped, by passing the
    ///     action to the closure.
    public init<Action>(_ state: AlertState<Action>, action: @escaping (Action?) -> Void) {
      if state.buttons.count == 2 {
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          primaryButton: .init(state.buttons[0], action: action),
          secondaryButton: .init(state.buttons[1], action: action)
        )
      } else {
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          dismissButton: state.buttons.first.map { .init($0, action: action) }
        )
      }
    }

    /// Creates an alert from alert state.
    ///
    /// - Parameters:
    ///   - state: Alert state used to populate the alert.
    ///   - action: An action handler, called when a button with an action is tapped, by passing the
    ///     action to the closure.
    public init<Action>(_ state: AlertState<Action>, action: @escaping (Action?) async -> Void) {
      if state.buttons.count == 2 {
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          primaryButton: .init(state.buttons[0], action: action),
          secondaryButton: .init(state.buttons[1], action: action)
        )
      } else {
        self.init(
          title: Text(state.title),
          message: state.message.map { Text($0) },
          dismissButton: state.buttons.first.map { .init($0, action: action) }
        )
      }
    }
  }
#endif  // canImport(SwiftUI)
