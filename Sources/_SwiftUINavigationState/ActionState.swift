import SwiftUI

public protocol ActionState {
  associatedtype Action
  associatedtype Body: View

  func body(withAction perform: @escaping (Action) -> Void) -> Body
}

public struct AnyActionState<Action>: ActionState {
  public typealias Action = Action

  public typealias Body = AnyView

  private let _body: (@escaping (Action) -> Void) -> AnyView

  public init<S: ActionState>(_ state: S) where S.Action == Action {
    self._body = { perform in
      AnyView(state.body(withAction: perform))
    }
  }

  public func body(withAction perform: @escaping (Action) -> Void) -> AnyView {
    self._body(perform)
  }
}

@resultBuilder
public enum ActionStateBuilder<Action> {
  public static func buildArray(
    _ components: [[AnyActionState<Action>]]
  ) -> [AnyActionState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildBlock(
    _ components: [AnyActionState<Action>]...
  ) -> [AnyActionState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildLimitedAvailability(
    _ component: [AnyActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component
  }

  public static func buildEither(
    first component: [AnyActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component
  }

  public static func buildEither(
    second component: [AnyActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component
  }

  public static func buildExpression(
    _ expression: AnyActionState<Action>
  ) -> [AnyActionState<Action>] {
    [expression]
  }

  public static func buildOptional(
    _ component: [AnyActionState<Action>]?
  ) -> [AnyActionState<Action>] {
    component ?? []
  }
}
