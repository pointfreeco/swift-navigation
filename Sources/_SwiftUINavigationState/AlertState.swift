import CustomDump
import SwiftUI

/// A data type that describes the state of an alert that can be shown to the user. The `Action`
/// generic is the type of actions that can be sent from tapping on a button in the alert.
///
/// This type can be used in your application's state in order to control the presentation and
/// actions of alerts. This API can be used to push the logic of alert presentation and actions into
/// your model, making it easier to test, and simplifying your view layer.
///
/// To use this API, you describe all of an alert's actions as cases in an enum:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   enum AlertAction {
///     case deleteButtonTapped
///   }
///   // ...
/// }
/// ```
///
/// You model the state for showing the alert in as a published field, which can start off `nil`:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   // ...
///   @Published var alert: AlertState<AlertAction>?
///   // ...
/// }
/// ```
///
/// And you define an endpoint for handling each alert action:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   // ...
///   func alertButtonTapped(_ action: AlertAction) {
///     switch action {
///     case .deleteButtonTapped:
///       // ...
///     }
///   }
/// }
/// ```
///
/// Then, in an endpoint that should display an alert, you can construct an ``AlertState`` value to
/// represent it:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   // ...
///   func deleteButtonTapped() {
///     self.alert = AlertState(
///       title: TextState("Delete"),
///       message: TextState(
///         "Are you sure you want to delete this? It cannot be undone."
///       ),
///       buttons: [
///         .destructive(
///           TextState("Confirm"),
///           action: .send(.deleteButtonTapped)
///         )
///       ]
///     )
///   }
/// }
/// ```
///
/// And in your view you can use the `.alert(unwrapping:action:)` view modifier to present the
/// alert:
///
/// ```swift
/// struct ItemView: View {
///   @ObservedObject var model: ItemModel
///
///   var body: some View {
///     VStack {
///       Button("Delete") {
///         self.model.deleteButtonTapped()
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
/// Even better, you can instantly write tests that your alert behavior works as expected:
///
/// ```swift
/// let model = ItemModel()
///
/// model.deleteButtonTapped()
/// XCTAssertEqual(
///   model.alert,
///   AlertState(
///     title: TextState("Delete"),
///     message: TextState(
///       "Are you sure you want to delete this? It cannot be undone."
///     ),
///     buttons: [
///       .destructive(
///         TextState("Confirm"),
///         action: .send(.deleteButtonTapped)
///       )
///     ]
///   )
/// )
///
/// model.alertButtonTapped(.deleteButtonTapped) {
///   // Also verify that delete logic executed correctly
/// }
/// model.alert = nil
/// ```
public struct AlertState<Action> {
  public let id = UUID()
  public var buttons: [Button]
  public var message: TextState?
  public var title: TextState

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  public init(
    title: TextState,
    message: TextState? = nil,
    buttons: [Button]
  ) {
    self.title = title
    self.message = message
    self.buttons = buttons
  }

  public init(
    title: TextState,
    message: TextState? = nil,
    dismissButton: Button? = nil
  ) {
    self.title = title
    self.message = message
    self.buttons = dismissButton.map { [$0] } ?? []
  }

  public init(
    title: TextState,
    message: TextState? = nil,
    primaryButton: Button,
    secondaryButton: Button
  ) {
    self.title = title
    self.message = message
    self.buttons = [primaryButton, secondaryButton]
  }

  public struct Button {
    public let id = UUID()
    public var action: ButtonAction?
    public var label: TextState
    public var role: ButtonRole?

    public static func cancel(
      _ label: TextState,
      action: ButtonAction? = nil
    ) -> Self {
      Self(action: action, label: label, role: .cancel)
    }

    public static func `default`(
      _ label: TextState,
      action: ButtonAction? = nil
    ) -> Self {
      Self(action: action, label: label, role: nil)
    }

    public static func destructive(
      _ label: TextState,
      action: ButtonAction? = nil
    ) -> Self {
      Self(action: action, label: label, role: .destructive)
    }

    public func withAction(_ perform: (Action) -> Void) {
      switch self.action?.type {
      case let .send(action):
        perform(action)
      case let .animatedSend(action, animation: animation):
        withAnimation(animation) {
          perform(action)
        }
      case .none:
        return
      }
    }
  }

  public struct ButtonAction {
    public let type: ActionType

    public static func send(_ action: Action) -> Self {
      .init(type: .send(action))
    }

    public static func send(_ action: Action, animation: Animation?) -> Self {
      .init(type: .animatedSend(action, animation: animation))
    }

    public enum ActionType {
      case send(Action)
      case animatedSend(Action, animation: Animation?)
    }
  }

  public enum ButtonRole {
    case cancel
    case destructive
  }
}

extension AlertState: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    Mirror(
      self,
      children: [
        "title": self.title,
        "message": self.message as Any,
        "buttons": self.buttons,
      ],
      displayStyle: .struct
    )
  }
}

extension AlertState.Button: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    Mirror(
      self,
      children: [
        self.role.map { "\($0)" } ?? "default": (
          self.label,
          action: self.action
        )
      ],
      displayStyle: .enum
    )
  }
}

extension AlertState.ButtonAction: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    switch self.type {
    case let .send(action):
      return Mirror(
        self,
        children: [
          "send": action
        ],
        displayStyle: .enum
      )
    case let .animatedSend(action, animation):
      return Mirror(
        self,
        children: [
          "send": (action, animation: animation)
        ],
        displayStyle: .enum
      )
    }
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

extension AlertState: Identifiable {}
extension AlertState.Button: Identifiable {}

extension AlertState.ButtonAction: Equatable where Action: Equatable {}
extension AlertState.ButtonAction.ActionType: Equatable where Action: Equatable {}
extension AlertState.ButtonRole: Equatable {}
extension AlertState.Button: Equatable where Action: Equatable {}

extension AlertState.ButtonAction: Hashable where Action: Hashable {}
extension AlertState.ButtonAction.ActionType: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .send(action), let .animatedSend(action, animation: _):
      hasher.combine(action)
    }
  }
}
extension AlertState.ButtonRole: Hashable {}
extension AlertState.Button: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.action)
    hasher.combine(self.label)
    hasher.combine(self.role)
  }
}

extension Alert {
  public init<Action>(_ state: AlertState<Action>, action: @escaping (Action) -> Void) {
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

extension Alert.Button {
  public init<Action>(_ button: AlertState<Action>.Button, action: @escaping (Action) -> Void) {
    let action = button.action.map { _ in { button.withAction(action) } }
    switch button.role {
    case .cancel:
      self = .cancel(Text(button.label), action: action)
    case .destructive:
      self = .destructive(Text(button.label), action: action)
    case .none:
      self = .default(Text(button.label), action: action)
    }
  }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension ButtonRole {
  public init<Action>(_ role: AlertState<Action>.ButtonRole) {
    switch role {
    case .cancel:
      self = .cancel
    case .destructive:
      self = .destructive
    }
  }
}

extension Button where Label == Text {
  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  public init<Action>(_ button: AlertState<Action>.Button, action: @escaping (Action) -> Void) {
    self.init(
      role: button.role.map(ButtonRole.init),
      action: { button.withAction(action) }
    ) {
      Text(button.label)
    }
  }
}
