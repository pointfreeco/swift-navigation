#if canImport(SwiftUI)
  import SwiftUI

  // NB: Deprecated after 0.5.0

  extension ButtonState {
    @available(*, deprecated, message: "Use 'ButtonStateAction<Action>' instead.")
    public typealias Handler = ButtonStateAction<Action>

    @available(*, deprecated, message: "Use 'ButtonStateAction<Action>' instead.")
    public typealias ButtonAction = ButtonStateAction<Action>

    @available(*, deprecated, message: "Use 'ButtonStateRole' instead.")
    public typealias Role = ButtonStateRole
  }

  extension ButtonStateAction {
    @available(*, deprecated, message: "Use 'ButtonState.withAction' instead.")
    public typealias ActionType = _ActionType
  }

  // NB: Deprecated after 0.3.0

  extension AlertState {
    @available(*, deprecated, message: "Use 'ButtonState<Action>' instead.")
    public typealias Button = ButtonState<Action>

    @available(*, deprecated, message: "Use 'ButtonStateAction<Action>' instead.")
    public typealias ButtonAction = ButtonStateAction<Action>

    @available(*, deprecated, message: "Use 'ButtonStateRole' instead.")
    public typealias ButtonRole = ButtonStateRole

    @available(
      iOS, introduced: 15, deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      macOS,
      introduced: 12,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      tvOS, introduced: 15, deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      watchOS,
      introduced: 8,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    public init(
      title: TextState,
      message: TextState? = nil,
      buttons: [ButtonState<Action>]
    ) {
      self.init(
        id: UUID(),
        buttons: buttons,
        message: message,
        title: title
      )
    }

    @available(
      iOS, introduced: 13, deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      macOS,
      introduced: 10.15,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      tvOS, introduced: 13, deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      watchOS,
      introduced: 6,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    public init(
      title: TextState,
      message: TextState? = nil,
      dismissButton: ButtonState<Action>? = nil
    ) {
      self.init(
        id: UUID(),
        buttons: dismissButton.map { [$0] } ?? [],
        message: message,
        title: title
      )
    }

    @available(
      iOS, introduced: 13, deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      macOS,
      introduced: 10.15,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      tvOS, introduced: 13, deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      watchOS,
      introduced: 6,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    public init(
      title: TextState,
      message: TextState? = nil,
      primaryButton: ButtonState<Action>,
      secondaryButton: ButtonState<Action>
    ) {
      self.init(
        id: UUID(),
        buttons: [primaryButton, secondaryButton],
        message: message,
        title: title
      )
    }
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
      _ label: TextState, action: ButtonStateAction<Action> = .send(nil)
    ) -> Self {
      Self(role: .cancel, action: action) {
        label
      }
    }

    public static func `default`(
      _ label: TextState, action: ButtonStateAction<Action> = .send(nil)
    ) -> Self {
      Self(action: action) {
        label
      }
    }

    public static func destructive(
      _ label: TextState, action: ButtonStateAction<Action> = .send(nil)
    ) -> Self {
      Self(role: .destructive, action: action) {
        label
      }
    }
  }

  @available(iOS 13, *)
  @available(macOS 12, *)
  @available(tvOS 13, *)
  @available(watchOS 6, *)
  extension ConfirmationDialogState {
    @available(*, deprecated, message: "Use 'ButtonState<Action>' instead.")
    public typealias Button = ButtonState<Action>

    @available(*, deprecated, renamed: "ConfirmationDialogStateTitleVisibility")
    public typealias Visibility = ConfirmationDialogStateTitleVisibility

    @available(
      iOS,
      introduced: 13,
      deprecated: 100000,
      message: "Use 'init(titleVisibility:title:actions:message:)' instead."
    )
    @available(
      macOS,
      introduced: 12,
      deprecated: 100000,
      message: "Use 'init(titleVisibility:title:actions:message:)' instead."
    )
    @available(
      tvOS,
      introduced: 13,
      deprecated: 100000,
      message: "Use 'init(titleVisibility:title:actions:message:)' instead."
    )
    @available(
      watchOS,
      introduced: 6,
      deprecated: 100000,
      message: "Use 'init(titleVisibility:title:actions:message:)' instead."
    )
    public init(
      title: TextState,
      titleVisibility: ConfirmationDialogStateTitleVisibility,
      message: TextState? = nil,
      buttons: [ButtonState<Action>] = []
    ) {
      self.init(
        id: UUID(),
        buttons: buttons,
        message: message,
        title: title,
        titleVisibility: titleVisibility
      )
    }

    @available(
      iOS,
      introduced: 13,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      macOS,
      introduced: 12,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      tvOS,
      introduced: 13,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    @available(
      watchOS,
      introduced: 6,
      deprecated: 100000,
      message: "Use 'init(title:actions:message:)' instead."
    )
    public init(
      title: TextState,
      message: TextState? = nil,
      buttons: [ButtonState<Action>] = []
    ) {
      self.init(
        id: UUID(),
        buttons: buttons,
        message: message,
        title: title,
        titleVisibility: .automatic
      )
    }
  }

  @available(iOS, introduced: 13, deprecated: 100000, renamed: "ConfirmationDialogState")
  @available(macOS, introduced: 12, unavailable)
  @available(tvOS, introduced: 13, deprecated: 100000, renamed: "ConfirmationDialogState")
  @available(watchOS, introduced: 6, deprecated: 100000, renamed: "ConfirmationDialogState")
  public typealias ActionSheetState<Action> = ConfirmationDialogState<Action>

  @available(
    iOS,
    introduced: 13,
    deprecated: 100000,
    message:
      "use 'View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)' instead."
  )
  @available(
    macOS,
    introduced: 12,
    unavailable
  )
  @available(
    tvOS,
    introduced: 13,
    deprecated: 100000,
    message:
      "use 'View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)' instead."
  )
  @available(
    watchOS,
    introduced: 6,
    deprecated: 100000,
    message:
      "use 'View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)' instead."
  )
  extension ActionSheet {
    public init<Action>(
      _ state: ConfirmationDialogState<Action>,
      action: @escaping (Action?) -> Void
    ) {
      self.init(
        title: Text(state.title),
        message: state.message.map { Text($0) },
        buttons: state.buttons.map { .init($0, action: action) }
      )
    }
  }

#endif  // canImport(SwiftUI)
