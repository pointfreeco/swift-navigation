#if canImport(SwiftUI)
  import CustomDump
  import SwiftUI

  public struct ButtonState<Action>: Identifiable {
    public let id: UUID
    public let action: ButtonStateAction<Action>
    public let label: TextState
    public let role: ButtonStateRole?

    init(
      id: UUID,
      action: ButtonStateAction<Action>,
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
      action: ButtonStateAction<Action> = .send(nil),
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
      case let .animatedSend(action, animation):
        withAnimation(animation) {
          perform(action)
        }
      }
    }

    /// Handle the button's action in an async closure.
    ///
    /// > Warning: Async closures cannot be performed with animation. If the underlying action is
    /// > animated, a runtime warning will be emitted.
    ///
    /// - Parameter perform: Unwraps and passes a button's action to a closure to be performed.
    public func withAction(_ perform: (Action?) async -> Void) async {
      switch self.action.type {
      case let .send(action):
        await perform(action)
      case let .animatedSend(action, _):
        var output = ""
        customDump(self.action, to: &output, indent: 4)
        runtimeWarn(
          """
          An animated action was performed asynchronously: …

            Action:
          \((output))

          Asynchronous actions cannot be animated. Evaluate this action in a synchronous closure, or \
          use 'SwiftUI.withAnimation' explicitly.
          """
        )
        await perform(action)
      }
    }

    /// Transforms a button state's action into a new action.
    ///
    /// - Parameter transform: A closure that transforms an optional action into a new optional
    ///   action.
    /// - Returns: Button state over a new action.
    public func map<NewAction>(_ transform: (Action?) -> NewAction?) -> ButtonState<NewAction> {
      ButtonState<NewAction>(
        id: self.id,
        action: self.action.map(transform),
        label: self.label,
        role: self.role
      )
    }
  }

  /// A type that wraps an action with additional context, _e.g._ for animation.
  public struct ButtonStateAction<Action> {
    public let type: _ActionType

    public static func send(_ action: Action?) -> Self {
      .init(type: .send(action))
    }

    public static func send(_ action: Action?, animation: Animation?) -> Self {
      .init(type: .animatedSend(action, animation: animation))
    }

    public var action: Action? {
      switch self.type {
      case let .animatedSend(action, animation: _), let .send(action):
        return action
      }
    }

    public func map<NewAction>(
      _ transform: (Action?) -> NewAction?
    ) -> ButtonStateAction<NewAction> {
      switch self.type {
      case let .animatedSend(action, animation: animation):
        return .send(transform(action), animation: animation)
      case let .send(action):
        return .send(transform(action))
      }
    }

    public enum _ActionType {
      case send(Action?)
      case animatedSend(Action?, animation: Animation?)
    }
  }

  /// A value that describes the purpose of a button.
  ///
  /// See `SwiftUI.ButtonRole` for more information.
  public enum ButtonStateRole: Sendable {
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

  extension ButtonStateAction: CustomDumpReflectable {
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

  extension ButtonStateAction: Equatable where Action: Equatable {}
  extension ButtonStateAction._ActionType: Equatable where Action: Equatable {}
  extension ButtonStateRole: Equatable {}
  extension ButtonState: Equatable where Action: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.action == rhs.action
        && lhs.label == rhs.label
        && lhs.role == rhs.role
    }
  }

  extension ButtonStateAction: Hashable where Action: Hashable {}
  extension ButtonStateAction._ActionType: Hashable where Action: Hashable {
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

  extension ButtonStateAction: Sendable where Action: Sendable {}
  extension ButtonStateAction._ActionType: Sendable where Action: Sendable {}
  extension ButtonState: Sendable where Action: Sendable {}

  // MARK: - SwiftUI bridging

  extension Alert.Button {
    /// Initializes a `SwiftUI.Alert.Button` from `ButtonState` and an action handler.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
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

    /// Initializes a `SwiftUI.Alert.Button` from `ButtonState` and an async action handler.
    ///
    /// > Warning: Async closures cannot be performed with animation. If the underlying action is
    /// > animated, a runtime warning will be emitted.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
    public init<Action>(_ button: ButtonState<Action>, action: @escaping (Action?) async -> Void) {
      let action = { _ = Task { await button.withAction(action) } }
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
    /// Initializes a `SwiftUI.Button` from `ButtonState` and an async action handler.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public init<Action>(_ button: ButtonState<Action>, action: @escaping (Action?) -> Void) {
      self.init(
        role: button.role.map(ButtonRole.init),
        action: { button.withAction(action) }
      ) {
        Text(button.label)
      }
    }

    /// Initializes a `SwiftUI.Button` from `ButtonState` and an action handler.
    ///
    /// > Warning: Async closures cannot be performed with animation. If the underlying action is
    /// > animated, a runtime warning will be emitted.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public init<Action>(_ button: ButtonState<Action>, action: @escaping (Action?) async -> Void) {
      self.init(
        role: button.role.map(ButtonRole.init),
        action: { Task { await button.withAction(action) } }
      ) {
        Text(button.label)
      }
    }
  }

  @usableFromInline
  func debugCaseOutput(_ value: Any) -> String {
    func debugCaseOutputHelp(_ value: Any) -> String {
      let mirror = Mirror(reflecting: value)
      switch mirror.displayStyle {
      case .enum:
        guard let child = mirror.children.first else {
          let childOutput = "\(value)"
          return childOutput == "\(type(of: value))" ? "" : ".\(childOutput)"
        }
        let childOutput = debugCaseOutputHelp(child.value)
        return ".\(child.label ?? "")\(childOutput.isEmpty ? "" : "(\(childOutput))")"
      case .tuple:
        return mirror.children.map { label, value in
          let childOutput = debugCaseOutputHelp(value)
          return
            "\(label.map { isUnlabeledArgument($0) ? "_:" : "\($0):" } ?? "")\(childOutput.isEmpty ? "" : " \(childOutput)")"
        }
        .joined(separator: ", ")
      default:
        return ""
      }
    }

    return (value as? CustomDebugStringConvertible)?.debugDescription
      ?? "\(typeName(type(of: value)))\(debugCaseOutputHelp(value))"
  }

  private func isUnlabeledArgument(_ label: String) -> Bool {
    label.firstIndex(where: { $0 != "." && !$0.isNumber }) == nil
  }

  @usableFromInline
  func typeName(_ type: Any.Type) -> String {
    var name = _typeName(type, qualified: true)
    if let index = name.firstIndex(of: ".") {
      name.removeSubrange(...index)
    }
    let sanitizedName =
      name
      .replacingOccurrences(
        of: #"<.+>|\(unknown context at \$[[:xdigit:]]+\)\."#,
        with: "",
        options: .regularExpression
      )
    return sanitizedName
  }
#endif  // canImport(SwiftUI)
