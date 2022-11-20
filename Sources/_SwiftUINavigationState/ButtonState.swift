import CustomDump
import SwiftUI

public struct ButtonState<Action>: Identifiable {
  public struct ButtonAction {
    public let type: _ActionType

    public static func send(_ action: Action) -> Self {
      .init(type: .send(action))
    }

    public static func send(_ action: Action, animation: Animation?) -> Self {
      .init(type: .animatedSend(action, animation: animation))
    }

    public enum _ActionType {
      case send(Action)
      case animatedSend(Action, animation: Animation?)
    }
  }

  public enum Role {
    case destructive
    case cancel
  }

  public let id = UUID()
  public let action: ButtonAction?
  public let label: TextState
  public let role: Role?

  public init(
    role: Role? = nil,
    action: ButtonAction? = nil,
    label: () -> TextState
  ) {
    self.role = role
    self.action = action
    self.label = label()
  }

  public init(
    role: Role? = nil,
    action: Action? = nil,
    label: () -> TextState
  ) {
    self.role = role
    self.action = action.map(ButtonAction.send)
    self.label = label()
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

extension ButtonState: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    var children: [(label: String?, value: Any)] = []
    if let role = self.role {
      children.append(("role", role))
    }
    if let action = self.action {
      children.append(("action", action))
    }
    children.append(("label", self.label))
    return Mirror(
      self,
      children: children,
      displayStyle: .struct
    )
  }
}

extension ButtonState.ButtonAction: CustomDumpReflectable {
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

extension ButtonState.ButtonAction: Equatable where Action: Equatable {}
extension ButtonState.ButtonAction._ActionType: Equatable where Action: Equatable {}
extension ButtonState.Role: Equatable {}
extension ButtonState: Equatable where Action: Equatable {}

extension ButtonState.ButtonAction: Hashable where Action: Hashable {}
extension ButtonState.ButtonAction._ActionType: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .send(action), let .animatedSend(action, animation: _):
      hasher.combine(action)
    }
  }
}
extension ButtonState.Role: Hashable {}
extension ButtonState: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.action)
    hasher.combine(self.label)
    hasher.combine(self.role)
  }
}

// MARK: - SwiftUI bridging

extension Alert.Button {
  public init<Action>(_ button: ButtonState<Action>, action: @escaping (Action) -> Void) {
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
  public init<Action>(_ role: ButtonState<Action>.Role) {
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
  public init<Action>(_ button: ButtonState<Action>, action: @escaping (Action) -> Void) {
    self.init(
      role: button.role.map(ButtonRole.init),
      action: { button.withAction(action) }
    ) {
      Text(button.label)
    }
  }
}

// MARK: - Deprecations

extension ButtonState.ButtonAction {
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
  public static func cancel(
    _ label: TextState,
    action: ButtonAction? = nil
  ) -> Self {
    Self(role: .cancel, action: action) {
      label
    }
  }

  public static func `default`(
    _ label: TextState,
    action: ButtonAction? = nil
  ) -> Self {
    Self(action: action) {
      label
    }
  }

  public static func destructive(
    _ label: TextState,
    action: ButtonAction? = nil
  ) -> Self {
    Self(role: .destructive, action: action) {
      label
    }
  }
}
