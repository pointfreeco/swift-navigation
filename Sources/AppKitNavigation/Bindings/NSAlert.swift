#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSAlert {
    /// Creates and returns a alert for displaying an alert using a data description.
    ///
    /// - Parameters:
    ///   - state: A data description of the alert.
    ///   - handler: A closure that is invoked with an action held in `state`.
    public convenience init<Action>(
        state: AlertState<Action>,
        handler: @escaping (_ action: Action?) -> Void
    ) {
        self.init()
        self.messageText = String(state: state.title)
        state.message.map { self.informativeText = String(state: $0) }

        for button in state.buttons {
            addButton(button, action: handler)
        }
    }
}

extension NSAlert {
    public func addButton<Action>(
        _ buttonState: ButtonState<Action>,
        action handler: @escaping (_ action: Action?) -> Void
    ) {
        let button = addButton(withTitle: String(state: buttonState.label))

        button.createActionProxyIfNeeded().addBindingAction { _ in
            buttonState.withAction(handler)
        }
        
        if buttonState.role == .destructive, #available(macOS 11.0, *) {
            button.hasDestructiveAction = true
        }
        if buttonState.role == .cancel {
            button.keyEquivalent = "\u{1b}"
        }
        
        if #available(macOS 12, *) {
            button.setAccessibilityLabel(buttonState.label.accessibilityLabel.map { String(state: $0) })
        }
    }
}
#endif
