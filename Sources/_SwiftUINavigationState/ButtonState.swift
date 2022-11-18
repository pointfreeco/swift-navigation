import CustomDump
import SwiftUI

public struct ButtonState<Action>: Identifiable {
  // TODO: Rename?
  public struct ButtonAction {
    public let type: ActionType

    public static func send(_ action: Action) -> Self {
      .init(type: .send(action))
    }

    public static func send(_ action: Action, animation: Animation?) -> Self {
      .init(type: .animatedSend(action, animation: animation))
    }

    // TODO: Rename?
    public enum ActionType {
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
    _ titleKey: LocalizedStringKey,
    role: Role? = nil,
    action: ButtonAction? = nil
  ) {
    self.role = role
    self.action = action
    self.label = TextState(titleKey)
  }

  @_disfavoredOverload
  public init<S: StringProtocol>(
    _ title: S,
    role: Role? = nil,
    action: ButtonAction? = nil
  ) {
    self.role = role
    self.action = action
    self.label = TextState(title)
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

@resultBuilder
public enum ButtonStateBuilder<Action> {
  public static func buildArray(_ components: [[ButtonState<Action>]]) -> [ButtonState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildBlock(_ components: [ButtonState<Action>]...) -> [ButtonState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildLimitedAvailability(_ component: [ButtonState<Action>]) -> [ButtonState<Action>] {
    component
  }

  public static func buildEither(first component: [ButtonState<Action>]) -> [ButtonState<Action>] {
    component
  }

  public static func buildEither(second component: [ButtonState<Action>]) -> [ButtonState<Action>] {
    component
  }

  public static func buildExpression(_ expression: ButtonState<Action>) -> [ButtonState<Action>] {
    [expression]
  }

  public static func buildOptional(_ component: [ButtonState<Action>]?) -> [ButtonState<Action>] {
    component ?? []
  }
}

extension ButtonState: CustomDumpReflectable {
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
extension ButtonState.ButtonAction.ActionType: Equatable where Action: Equatable {}
extension ButtonState.Role: Equatable {}
extension ButtonState: Equatable where Action: Equatable {}

extension ButtonState.ButtonAction: Hashable where Action: Hashable {}
extension ButtonState.ButtonAction.ActionType: Hashable where Action: Hashable {
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
