#if canImport(UIKit) && !os(watchOS)
  import UIKit

  @available(iOS 13, *)
  @available(macCatalyst 13, *)
  @available(macOS, unavailable)
  @available(tvOS 13, *)
  @available(watchOS, unavailable)
  extension UIAlertController {
    /// Creates and returns a view controller for displaying an alert using a data description.
    ///
    /// - Parameters:
    ///   - state: A data description of the alert.
    ///   - handler: A closure that is invoked with an action held in `state`.
    public convenience init<Action>(
      state: AlertState<Action>,
      handler: @escaping (_ action: Action?) -> Void = { (_: Never?) in }
    ) {
      self.init(
        title: String(state: state.title),
        message: state.message.map { String(state: $0) },
        preferredStyle: .alert
      )
      for button in state.buttons {
        addAction(UIAlertAction(button, action: handler))
      }
    }

    /// Creates and returns a view controller for displaying an action sheet using a data
    /// description.
    ///
    /// - Parameters:
    ///   - state: A data description of the alert.
    ///   - handler: A closure that is invoked with an action held in `state`.
    public convenience init<Action>(
      state: ConfirmationDialogState<Action>,
      handler: @escaping (_ action: Action?) -> Void = { (_: Never?) in }
    ) {
      self.init(
        title: {
          switch state.titleVisibility {
          case .automatic:
            let title = String(state: state.title)
            return title.isEmpty ? nil : title
          case .hidden:
            return nil
          case .visible:
            return String(state: state.title)
          @unknown default:
            let title = String(state: state.title)
            return title.isEmpty ? nil : title
          }
        }(),
        message: state.message.map { String(state: $0) },
        preferredStyle: .actionSheet
      )
      for button in state.buttons {
        addAction(UIAlertAction(button, action: handler))
      }
    }
  }

  @available(iOS 13, *)
  @available(macCatalyst 13, *)
  @available(macOS, unavailable)
  @available(tvOS 13, *)
  @available(watchOS, unavailable)
  extension UIAlertAction.Style {
    public init(_ role: ButtonStateRole) {
      switch role {
      case .cancel:
        self = .cancel
      case .destructive:
        self = .destructive
      @unknown default:
        self = .default
      }
    }
  }

  @available(iOS 13, *)
  @available(macCatalyst 13, *)
  @available(macOS, unavailable)
  @available(tvOS 13, *)
  @available(watchOS, unavailable)
  extension UIAlertAction {
    public convenience init<Action>(
      _ button: ButtonState<Action>,
      action handler: @escaping (_ action: Action?) -> Void = { (_: Never?) in }
    ) {
      self.init(
        title: String(state: button.label),
        style: button.role.map(UIAlertAction.Style.init) ?? .default
      ) { _ in
        button.withAction(handler)
      }
      if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
        self.accessibilityLabel = button.label.accessibilityLabel.map { String(state: $0) }
      }
    }
  }
#endif
