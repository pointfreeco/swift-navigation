#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit

  /// Runs a closure for each notification of a name that an object posts, until invalidated.
  ///
  /// Observes through a selector rather than a block: a block observer's closure has to be
  /// sendable, and bindings hand it closures that are not, such as an app's lookup of a row's
  /// item. The objects bindings observe post their notifications on the main thread.
  @MainActor
  final class NotificationObserver: NSObject {
    private let handler: (Notification) -> Void

    init(
      name: Notification.Name,
      object: AnyObject,
      handler: @escaping (Notification) -> Void
    ) {
      self.handler = handler
      super.init()
      NotificationCenter.default.addObserver(
        self, selector: #selector(receive(_:)), name: name, object: object
      )
    }

    func invalidate() {
      NotificationCenter.default.removeObserver(self)
    }

    @objc private func receive(_ notification: Notification) {
      handler(notification)
    }
  }
#endif
