#if canImport(SwiftUI)
  @resultBuilder
  public enum ButtonStateBuilder<Action> {
    public static func buildArray(_ components: [[ButtonState<Action>]]) -> [ButtonState<Action>] {
      components.flatMap { $0 }
    }

    public static func buildBlock(_ components: [ButtonState<Action>]...) -> [ButtonState<Action>] {
      components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(
      _ component: [ButtonState<Action>]
    ) -> [ButtonState<Action>] {
      component
    }

    public static func buildEither(first component: [ButtonState<Action>]) -> [ButtonState<Action>]
    {
      component
    }

    public static func buildEither(second component: [ButtonState<Action>]) -> [ButtonState<Action>]
    {
      component
    }

    public static func buildExpression(_ expression: ButtonState<Action>) -> [ButtonState<Action>] {
      [expression]
    }

    public static func buildOptional(_ component: [ButtonState<Action>]?) -> [ButtonState<Action>] {
      component ?? []
    }
  }
#endif  // canImport(SwiftUI)
