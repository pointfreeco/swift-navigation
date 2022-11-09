import CustomDump
import SwiftUI

/// A data type that describes the state of a confirmation dialog that can be shown to the user. The
/// `Action` generic is the type of actions that can be sent from tapping on a button in the sheet.
///
/// This type can be used in your application's state in order to control the presentation or
/// dismissal of dialogs. It is preferable to use this API instead of the default SwiftUI API for
/// dialogs because SwiftUI uses 2-way bindings in order to control the showing and dismissal of
/// dialogs, and that does not play nicely with the Composable Architecture. The library requires
/// that all state mutations happen by sending an action so that a reducer can handle that logic,
/// which greatly simplifies how data flows through your application, and gives you instant
/// testability on all parts of your application.
///
/// To use this API, you model all the dialog actions in your domain's action enum:
///
/// ```swift
/// enum Action: Equatable {
///   case cancelTapped
///   case deleteTapped
///   case favoriteTapped
///   case infoTapped
///
///   // Your other actions
/// }
/// ```
///
/// And you model the state for showing the dialog in your domain's state, and it can start off in a
/// `nil` state:
///
/// ```swift
/// struct State: Equatable {
///   var confirmationDialog: ConfirmationDialogState<AppAction>?
///
///   // Your other state
/// }
/// ```
///
/// Then, in the reducer you can construct a `ConfirmationDialogState` value to represent the dialog
/// you want to show to the user:
///
/// ```swift
/// func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
///   switch action {
///   case .cancelTapped:
///     state.confirmationDialog = nil
///     return .none
///
///   case .deleteTapped:
///     state.confirmationDialog = nil
///     // Do deletion logic...
///
///   case .favoriteTapped:
///     state.confirmationDialog = nil
///     // Do favoriting logic
///
///   case .infoTapped:
///     state.confirmationDialog = ConfirmationDialogState(
///       title: "What would you like to do?",
///       buttons: [
///         .default(TextState("Favorite"), action: .send(.favoriteTapped)),
///         .destructive(TextState("Delete"), action: .send(.deleteTapped)),
///         .cancel(),
///       ]
///     )
///     return .none
///   }
/// }
/// ```
///
/// And then, in your view you can use the `confirmationDialog(_:dismiss:)` method on `View` in
/// order to present the dialog in a way that works best with the Composable Architecture:
///
/// ```swift
/// Button("Info") { viewStore.send(.infoTapped) }
///   .confirmationDialog(
///     self.store.scope(state: \.confirmationDialog),
///     dismiss: .cancelTapped
///   )
/// ```
///
/// This makes your reducer in complete control of when the dialog is shown or dismissed, and makes
/// it so that any choice made in the dialog is automatically fed back into the reducer so that you
/// can handle its logic.
///
/// Even better, you can instantly write tests that your dialog behavior works as expected:
///
/// ```swift
/// let store = TestStore(
///   initialState: Feature.State(),
///   reducer: Feature()
/// )
///
/// store.send(.infoTapped) {
///   $0.confirmationDialog = ConfirmationDialogState(
///     title: "What would you like to do?",
///     buttons: [
///       .default(TextState("Favorite"), send: .favoriteTapped),
///       .destructive(TextState("Delete"), send: .deleteTapped),
///       .cancel(),
///     ]
///   )
/// }
/// store.send(.favoriteTapped) {
///   $0.confirmationDialog = nil
///   // Also verify that favoriting logic executed correctly
/// }
/// ```
@available(iOS 13, *)
@available(macOS 12, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
public struct ConfirmationDialogState<Action> {
  public let id = UUID()
  public var buttons: [Button]
  public var message: TextState?
  public var title: TextState
  public var titleVisibility: Visibility

  @available(iOS 15, *)
  @available(macOS 12, *)
  @available(tvOS 15, *)
  @available(watchOS 8, *)
  public init(
    title: TextState,
    titleVisibility: Visibility,
    message: TextState? = nil,
    buttons: [Button] = []
  ) {
    self.buttons = buttons
    self.message = message
    self.title = title
    self.titleVisibility = titleVisibility
  }

  public init(
    title: TextState,
    message: TextState? = nil,
    buttons: [Button] = []
  ) {
    self.buttons = buttons
    self.message = message
    self.title = title
    self.titleVisibility = .automatic
  }

  public typealias Button = AlertState<Action>.Button

  public enum Visibility {
    case automatic
    case hidden
    case visible
  }
}

@available(iOS 13, *)
@available(macOS 12, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
extension ConfirmationDialogState: CustomDumpReflectable {
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
extension ConfirmationDialogState: Identifiable {}

@available(iOS, introduced: 13, deprecated: 100000.0, message: "use `View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)`instead.")
@available(macOS, unavailable)
@available(tvOS, introduced: 13, deprecated: 100000.0, message: "use `View.confirmationDialog(title:isPresented:titleVisibility:presenting:actions:)`instead.")
@available(watchOS, introduced: 6, deprecated: 100000.0, message: "use `View.confirmationDialog(title:isPresented:titleVisibility:presenting:actions:)`instead.")
extension ActionSheet {
  public init<Action>(
    _ state: ConfirmationDialogState<Action>,
    action: @escaping (Action) -> Void
  ) {
    self.init(
      title: Text(state.title),
      message: state.message.map { Text($0) },
      buttons: state.buttons.map { .init($0, action: action) }
    )
  }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Visibility {
  public init<Action>(_ visibility: ConfirmationDialogState<Action>.Visibility) {
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
