// MARK: - Deprecated after 2.1.0

@available(*, deprecated, renamed: "ObserveToken")
public typealias ObservationToken = ObserveToken

// MARK: - Deprecated after 2.0.0

extension AlertState {
  @available(*, deprecated, message: "Use 'init(title:actions:message:)' instead.")
  public init(
    title: TextState,
    message: TextState? = nil,
    buttons: [ButtonState<Action>]
  ) {
    self.init(
      title: { title },
      actions: {
        for button in buttons {
          button
        }
      },
      message: message.map { message in { message } }
    )
  }

  @available(*, deprecated, message: "Use 'init(title:actions:message:)' instead.")
  public init(
    title: TextState,
    message: TextState? = nil,
    dismissButton: ButtonState<Action>? = nil
  ) {
    self.init(
      title: { title },
      actions: {
        if let dismissButton {
          dismissButton
        }
      },
      message: message.map { message in { message } }
    )
  }

  @available(*, deprecated, message: "Use 'init(title:actions:message:)' instead.")
  public init(
    title: TextState,
    message: TextState? = nil,
    primaryButton: ButtonState<Action>,
    secondaryButton: ButtonState<Action>
  ) {
    self.init(
      title: { title },
      actions: {
        primaryButton
        secondaryButton
      },
      message: message.map { message in { message } }
    )
  }
}

extension ButtonState {
  @available(*, deprecated, message: "Use 'ButtonState(role: .cancel, action:label:)' instead.")
  public static func cancel(
    _ label: TextState, action: ButtonStateAction<Action> = .send(nil)
  ) -> Self {
    Self(role: .cancel, action: action) {
      label
    }
  }

  @available(*, deprecated, message: "Use 'ButtonState(action:label:)' instead.")
  public static func `default`(
    _ label: TextState, action: ButtonStateAction<Action> = .send(nil)
  ) -> Self {
    Self(action: action) {
      label
    }
  }

  @available(
    *, deprecated, message: "Use 'ButtonState(role: .destructive, action:label:)' instead."
  )
  public static func destructive(
    _ label: TextState, action: ButtonStateAction<Action> = .send(nil)
  ) -> Self {
    Self(role: .destructive, action: action) {
      label
    }
  }
}

@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
extension ConfirmationDialogState {
  @available(*, deprecated, message: "Use 'init(titleVisibility:title:actions:message:)' instead.")
  public init(
    title: TextState,
    titleVisibility: ConfirmationDialogStateTitleVisibility,
    message: TextState? = nil,
    buttons: [ButtonState<Action>] = []
  ) {
    self.init(
      titleVisibility: titleVisibility,
      title: { title },
      actions: {
        for button in buttons {
          button
        }
      },
      message: message.map { message in { message } }
    )
  }

  @available(*, deprecated, message: "Use 'init(title:actions:message:)' instead.")
  public init(
    title: TextState,
    message: TextState? = nil,
    buttons: [ButtonState<Action>] = []
  ) {
    self.init(
      title: { title },
      actions: {
        for button in buttons {
          button
        }
      },
      message: message.map { message in { message } }
    )
  }
}

@available(iOS, introduced: 13, deprecated: 100000, renamed: "ConfirmationDialogState")
@available(macOS, introduced: 12, unavailable)
@available(tvOS, introduced: 13, deprecated: 100000, renamed: "ConfirmationDialogState")
@available(watchOS, introduced: 6, deprecated: 100000, renamed: "ConfirmationDialogState")
public typealias ActionSheetState<Action> = ConfirmationDialogState<Action>
