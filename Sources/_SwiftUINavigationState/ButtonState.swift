import CustomDump
import SwiftUI

public struct ButtonState<Action>: Identifiable {
  /// A type that wraps an action with additional context, _e.g._ for animation.
  public struct Handler {
    public let type: _ActionType

    public static func send(_ action: Action?) -> Self {
      .init(type: .send(action))
    }

    public static func send(_ action: Action?, animation: Animation?) -> Self {
      .init(type: .animatedSend(action, animation: animation))
    }

    public enum _ActionType {
      case send(Action?)
      case animatedSend(Action?, animation: Animation?)
    }

    public var action: Action? {
      switch self.type {
      case let .animatedSend(action, animation: _), let .send(action):
        return action
      }
    }

    public func map<NewAction>(
      _ transform: (Action?) -> NewAction?
    ) -> ButtonState<NewAction>.Handler {
      switch self.type {
      case let .animatedSend(action, animation: animation):
        return .send(transform(action), animation: animation)
      case let .send(action):
        return .send(transform(action))
      }
    }
  }

  public let id: UUID
  public let action: Handler
  public let label: TextState
  public let role: ButtonStateRole?

  init(
    id: UUID,
    action: Handler,
    label: TextState,
    role: ButtonStateRole?
  ) {
    self.id = id
    self.action = action
    self.label = label
    self.role = role
  }

  /// Creates button state.
  ///
  /// - Parameters:
  ///   - role: An optional semantic role that describes the button. A value of `nil` means that the
  ///     button doesn't have an assigned role.
  ///   - action: The action to send when the user interacts with the button.
  ///   - label: A view that describes the purpose of the button's `action`.
  public init(
    role: ButtonStateRole? = nil,
    action: Handler = .send(nil),
    label: () -> TextState
  ) {
    self.init(id: UUID(), action: action, label: label(), role: role)
  }

  /// Creates button state.
  ///
  /// - Parameters:
  ///   - role: An optional semantic role that describes the button. A value of `nil` means that the
  ///     button doesn't have an assigned role.
  ///   - action: The action to send when the user interacts with the button.
  ///   - label: A view that describes the purpose of the button's `action`.
  public init(
    role: ButtonStateRole? = nil,
    action: Action,
    label: () -> TextState
  ) {
    self.init(id: UUID(), action: .send(action), label: label(), role: role)
  }

  /// Handle the button's action in a closure.
  ///
  /// - Parameter perform: Unwraps and passes a button's action to a closure to be performed. If the
  ///   action has an associated animation, the context will be wrapped using SwiftUI's
  ///   `withAnimation`.
  public func withAction(_ perform: (Action?) -> Void) {
    switch self.action.type {
    case let .send(action):
      perform(action)
    case let .animatedSend(action, animation: animation):
      withAnimation(animation) {
        perform(action)
      }
    }
  }

  public func map<NewAction>(_ transform: (Action?) -> NewAction?) -> ButtonState<NewAction> {
    ButtonState<NewAction>(
      id: self.id,
      action: self.action.map(transform),
      label: self.label,
      role: self.role
    )
  }
}

/// A value that describes the purpose of a button.
///
/// See `SwiftUI.ButtonRole` for more information.
public enum ButtonStateRole {
  /// A role that indicates a cancel button.
  ///
  /// See `SwiftUI.ButtonRole.cancel` for more information.
  case cancel

  /// A role that indicates a destructive button.
  ///
  /// See `SwiftUI.ButtonRole.destructive` for more information.
  case destructive
}

extension ButtonState: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    var children: [(label: String?, value: Any)] = []
    if let role = self.role {
      children.append(("role", role))
    }
    children.append(("action", self.action))
    children.append(("label", self.label))
    return Mirror(
      self,
      children: children,
      displayStyle: .struct
    )
  }
}

extension ButtonState.Handler: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    switch self.type {
    case let .send(action):
      return Mirror(
        self,
        children: [
          "send": action as Any
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

extension ButtonState.Handler: Equatable where Action: Equatable {}
extension ButtonState.Handler._ActionType: Equatable where Action: Equatable {}
extension ButtonStateRole: Equatable {}
extension ButtonState: Equatable where Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.action == rhs.action
      && lhs.label == rhs.label
      && lhs.role == rhs.role
  }
}

extension ButtonState.Handler: Hashable where Action: Hashable {}
extension ButtonState.Handler._ActionType: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .send(action), let .animatedSend(action, animation: _):
      hasher.combine(action)
    }
  }
}
extension ButtonStateRole: Hashable {}
extension ButtonState: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.action)
    hasher.combine(self.label)
    hasher.combine(self.role)
  }
}

// MARK: - SwiftUI bridging

extension Alert.Button {
  public init<Action>(_ button: ButtonState<Action>, action: @escaping (Action?) -> Void) {
    let action = { button.withAction(action) }
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
  public init(_ role: ButtonStateRole) {
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
  public init<Action>(_ button: ButtonState<Action>, action: @escaping (Action?) -> Void) {
    self.init(
      role: button.role.map(ButtonRole.init),
      action: { button.withAction(action) }
    ) {
      Text(button.label)
    }
  }
}

// MARK: - Deprecations

extension ButtonState {
  @available(*, deprecated, renamed: "Handler")
  public typealias ButtonAction = Handler

  @available(*, deprecated, renamed: "ButtonStateRole")
  public typealias Role = ButtonStateRole
}

extension ButtonState.Handler {
  @available(*, deprecated, message: "Use 'ButtonState.withAction' instead.")
  public typealias ActionType = _ActionType
}

@available(
  iOS,
  introduced: 13,
  deprecated: 100000,
  message: "Use 'ButtonState.init(role:action:label:)' instead."
)
@available(
  macOS, introduced: 10.15,
  deprecated: 100000,
  message: "Use 'ButtonState.init(role:action:label:)' instead."
)
@available(
  tvOS,
  introduced: 13,
  deprecated: 100000,
  message: "Use 'ButtonState.init(role:action:label:)' instead."
)
@available(
  watchOS,
  introduced: 6,
  deprecated: 100000,
  message: "Use 'ButtonState.init(role:action:label:)' instead."
)
extension ButtonState {
  public static func cancel(_ label: TextState, action: Handler = .send(nil)) -> Self {
    Self(role: .cancel, action: action) {
      label
    }
  }

  public static func `default`(_ label: TextState, action: Handler = .send(nil)) -> Self {
    Self(action: action) {
      label
    }
  }

  public static func destructive(_ label: TextState, action: Handler = .send(nil)) -> Self {
    Self(role: .destructive, action: action) {
      label
    }
  }
}
