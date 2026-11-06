#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  public import AppKit

  // MARK: - Modal loop

  @MainActor
  extension NSObject {
    /// Runs a window, an alert, or a save or open panel modally while a binding to a Boolean value
    /// you provide is true.
    ///
    /// The content runs in an application-modal loop: the rest of the app takes no input until
    /// the loop ends. Setting the binding to `false` ends it. When the user ends the content —
    /// closes the window, clicks a button of the alert, dismisses the panel — the binding is set
    /// to `false`. A modal presented while another one is running runs on top of it.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to run the content.
    ///   - onDismiss: The closure to execute once the content has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to run.
    /// - Returns: A token that stops following the binding once cancelled. Content that is
    ///   running then keeps running until the user ends it.
    @discardableResult
    public func modal<Content: ModalContent>(
      isPresented: UIBinding<Bool>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> Content
    ) -> ObserveToken {
      bindPresentation(
        ModalLoopStyle<Content>(),
        item: isPresented.toOptionalUnit,
        id: { $0.id },
        onDismiss: onDismiss
      ) { _ in
        content()
      }
    }

    /// Runs a window, an alert, or a save or open panel modally while a binding to an optional
    /// item holds a value.
    ///
    /// The content runs in an application-modal loop, as with
    /// ``modal(isPresented:onDismiss:content:)``. If the item's identity changes, the content
    /// ends, and once it has left the screen, content for the new item runs.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the content. While it holds a
    ///     value, the value is passed to `content`. When the user ends the content, the binding is
    ///     set to `nil`.
    ///   - onDismiss: The closure to execute once the content has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to run for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func modal<Item: Identifiable, Content: ModalContent>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> Content
    ) -> ObserveToken {
      bindPresentation(ModalLoopStyle<Content>(), item: item, id: { $0.id }, onDismiss: onDismiss) {
        content($0.wrappedValue)
      }
    }

    /// Runs a window, an alert, or a save or open panel modally while a binding to an optional
    /// item holds a value, passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the content. While it holds a
    ///     value, a binding to the value is passed to `content`. When the user ends the content,
    ///     the binding is set to `nil`.
    ///   - onDismiss: The closure to execute once the content has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to run for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func modal<Item: Identifiable, Content: ModalContent>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
      bindPresentation(
        ModalLoopStyle<Content>(), item: item, id: { $0.id }, onDismiss: onDismiss, content: content
      )
    }

    /// Runs a window, an alert, or a save or open panel modally while a binding to an optional
    /// item holds a value, telling items apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the content. While it holds a
    ///     value, the value is passed to `content`. When the user ends the content, the binding is
    ///     set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the content ends, and once
    ///     it has left the screen, content for the new item runs.
    ///   - onDismiss: The closure to execute once the content has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to run for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func modal<Item, Identifier: Hashable, Content: ModalContent>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> Content
    ) -> ObserveToken {
      bindPresentation(
        ModalLoopStyle<Content>(), item: item, id: { $0[keyPath: id] }, onDismiss: onDismiss
      ) {
        content($0.wrappedValue)
      }
    }

    /// Runs a window, an alert, or a save or open panel modally while a binding to an optional
    /// item holds a value, telling items apart by the identifier at a key path and passing the
    /// content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the content. While it holds a
    ///     value, a binding to the value is passed to `content`. When the user ends the content,
    ///     the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the content ends, and once
    ///     it has left the screen, content for the new item runs.
    ///   - onDismiss: The closure to execute once the content has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to run for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func modal<Item, Identifier: Hashable, Content: ModalContent>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
      bindPresentation(
        ModalLoopStyle<Content>(),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss,
        content: content
      )
    }
  }

  // MARK: - Modal session

  @MainActor
  extension NSObject {
    /// Shows a window in a modal session while a binding to a Boolean value you provide is true.
    ///
    /// Unlike ``modal(isPresented:onDismiss:content:)``, nothing waits for the session to end: the
    /// window takes the app's input while the rest of the app keeps running. Setting the binding to
    /// `false` closes the window, which ends the session. When the user closes the window, the
    /// binding is set to `false`.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to show the window.
    ///   - onDismiss: The closure to execute once the window has closed.
    ///   - content: A closure that returns the window to show.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func modalSession(
      isPresented: UIBinding<Bool>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> NSWindow
    ) -> ObserveToken {
      bindPresentation(
        ModalSessionStyle(),
        item: isPresented.toOptionalUnit,
        id: { $0.id },
        onDismiss: onDismiss
      ) { _ in
        content()
      }
    }

    /// Shows a window in a modal session while a binding to an optional item holds a value.
    ///
    /// If the item's identity changes, the window closes, and a window for the new item opens.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the window. While it holds a value,
    ///     the value is passed to `content`. When the user closes the window, the binding is set
    ///     to `nil`.
    ///   - onDismiss: The closure to execute once the window has closed.
    ///   - content: A closure that returns the window to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func modalSession<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSWindow
    ) -> ObserveToken {
      bindPresentation(ModalSessionStyle(), item: item, id: { $0.id }, onDismiss: onDismiss) {
        content($0.wrappedValue)
      }
    }

    /// Shows a window in a modal session while a binding to an optional item holds a value,
    /// passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the window. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user closes the window, the
    ///     binding is set to `nil`.
    ///   - onDismiss: The closure to execute once the window has closed.
    ///   - content: A closure that returns the window to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func modalSession<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSWindow
    ) -> ObserveToken {
      bindPresentation(
        ModalSessionStyle(), item: item, id: { $0.id }, onDismiss: onDismiss, content: content
      )
    }

    /// Shows a window in a modal session while a binding to an optional item holds a value,
    /// telling items apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the window. While it holds a value,
    ///     the value is passed to `content`. When the user closes the window, the binding is set
    ///     to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the window closes, and a
    ///     window for the new item opens.
    ///   - onDismiss: The closure to execute once the window has closed.
    ///   - content: A closure that returns the window to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func modalSession<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSWindow
    ) -> ObserveToken {
      bindPresentation(
        ModalSessionStyle(), item: item, id: { $0[keyPath: id] }, onDismiss: onDismiss
      ) {
        content($0.wrappedValue)
      }
    }

    /// Shows a window in a modal session while a binding to an optional item holds a value,
    /// telling items apart by the identifier at a key path and passing the content a binding to
    /// the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the window. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user closes the window, the
    ///     binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the window closes, and a
    ///     window for the new item opens.
    ///   - onDismiss: The closure to execute once the window has closed.
    ///   - content: A closure that returns the window to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func modalSession<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSWindow
    ) -> ObserveToken {
      bindPresentation(
        ModalSessionStyle(),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss,
        content: content
      )
    }
  }

  // MARK: - Styles

  /// Runs content in an application-modal loop of its own.
  @MainActor
  private struct ModalLoopStyle<Content: ModalContent>: PresentationStyle {
    func begin(
      _ content: Content,
      transaction: UITransaction,
      didEnd: @escaping @MainActor () -> Void
    ) {
      let window = content._appKitNavigationWindow
      nonisolated(unsafe) let content = content
      ModalStack.startLoop {
        guard !ModalStack.takeEndRequest(for: window) else {
          // NB: Ended before it got to run.
          didEnd()
          return
        }
        // NB: A window's close button closes the window but leaves the modal loop running it.
        let closeObserver = NotificationObserver(
          name: NSWindow.willCloseNotification, object: window
        ) { _ in
          if NSApplication.shared.modalWindow === window {
            ModalStack.end(window) {
              NSApplication.shared.stopModal()
            }
          }
        }
        content._appKitNavigationRunModal()
        closeObserver.invalidate()
        ModalStack.modalDidEnd(window)
        // NB: Ending a modal loop does not take its window off screen. Alerts and panels order
        //     themselves out; a plain window stays up unless it is ordered out here.
        if window.isVisible {
          window.orderOut(nil)
        }
        didEnd()
      }
    }

    func end(_ content: Content, transaction: UITransaction) {
      ModalStack.end(content._appKitNavigationWindow) {
        NSApplication.shared.stopModal()
      }
    }
  }

  /// Shows a window in a modal session: the window takes the app's input, but nothing waits for
  /// it.
  @MainActor
  private struct ModalSessionStyle: PresentationStyle {
    func begin(
      _ window: NSWindow,
      transaction: UITransaction,
      didEnd: @escaping @MainActor () -> Void
    ) {
      let session = NSApplication.shared.beginModalSession(for: window)
      let closeObserver = OneTimeObserver()
      // NB: Closing the window is what ends the session, whether the user closed it or 'end' did.
      closeObserver.observer = NotificationObserver(
        name: NSWindow.willCloseNotification, object: window
      ) { _ in
        closeObserver.invalidate()
        NSApplication.shared.endModalSession(session)
        ModalStack.modalDidEnd(window)
        // NB: The window is still on screen while it is about to close.
        _ = RunLoopWait.until({ !window.isVisible }, then: didEnd)
      }
    }

    func end(_ window: NSWindow, transaction: UITransaction) {
      ModalStack.end(window) {
        window.close()
      }
    }
  }

  /// Keeps a notification observer alive until it has fired once.
  @MainActor
  private final class OneTimeObserver {
    var observer: NotificationObserver?

    func invalidate() {
      observer?.invalidate()
      observer = nil
    }
  }

  /// Starts and ends the modal loops and sessions this library runs, in an order AppKit can follow.
  ///
  /// - AppKit only stops the innermost modal: asked to stop one that has another modal on top, it
  ///   stops that other one instead. So a modal asked to end while it is covered ends once the
  ///   modals above it have ended, and one asked to end before it got to run does not run at all.
  /// - A modal loop asked to stop goes on running until it handles its next event. A loop started
  ///   on top of it in the meantime makes AppKit lose that request, and the first loop never
  ///   returns. So new loops wait until every loop asked to stop has returned.
  @MainActor
  private enum ModalStack {
    private static var windowsToEnd: [(window: NSWindow, end: @MainActor () -> Void)] = []
    private static var endingWindows: [NSWindow] = []
    private static var loopsToStart: [@MainActor () -> Void] = []
    private static var runLoopObserver: CFRunLoopObserver?

    /// Runs `run`, which runs a modal loop, from a run-loop block once no modal loop is on its way
    /// out.
    ///
    /// Never from a main-queue block, such as the 'observe' re-run that presents the content: the
    /// main queue is serial, so nothing else enqueued on it would run until the loop ended — not
    /// the re-run that ends the loop when the binding is set to 'nil', nor any main-actor task.
    /// Not from inside the presenter either, which would then stay on the stack, and alive, for as
    /// long as the loop runs, and could not end the loop when its owner goes away. The block runs
    /// in the modal panel mode as well as the default one, so that a modal presented from inside
    /// another modal loop starts on top of it.
    static func startLoop(_ run: @escaping @MainActor () -> Void) {
      RunLoop.main.perform(inModes: [.default, .modalPanel]) {
        MainActor._assumeIsolated {
          if endingWindows.isEmpty {
            run()
          } else {
            loopsToStart.append(run)
          }
        }
      }
    }

    /// Ends the modal showing `window` with `end`: right away if it is the topmost modal,
    /// otherwise once it is.
    static func end(_ window: NSWindow, with end: @escaping @MainActor () -> Void) {
      if NSApplication.shared.modalWindow === window {
        endingWindows.append(window)
        end()
        return
      }
      windowsToEnd.append((window, end))
      startObserving()
    }

    /// Whether `window` was asked to end before its modal started, and forgets the request.
    static func takeEndRequest(for window: NSWindow) -> Bool {
      guard windowsToEnd.contains(where: { $0.window === window }) else { return false }
      modalDidEnd(window)
      return true
    }

    /// Forgets everything about the modal showing `window`, once it has ended, and starts the
    /// loops that were waiting for it.
    static func modalDidEnd(_ window: NSWindow) {
      windowsToEnd.removeAll { $0.window === window }
      if windowsToEnd.isEmpty {
        stopObserving()
      }
      endingWindows.removeAll { $0 === window }
      guard endingWindows.isEmpty, !loopsToStart.isEmpty else { return }
      let loops = loopsToStart
      loopsToStart = []
      for loop in loops {
        startLoop(loop)
      }
    }

    private static func startObserving() {
      guard runLoopObserver == nil else { return }
      // NB: Checked each time the run loop is about to wait, in every mode a modal loop runs in.
      let runLoopObserver = CFRunLoopObserverCreateWithHandler(
        nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 0
      ) { _, _ in
        MainActor._assumeIsolated {
          ModalStack.endTheTopmostModalIfAsked()
        }
      }
      CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopObserver, .commonModes)
      self.runLoopObserver = runLoopObserver
    }

    private static func stopObserving() {
      guard let runLoopObserver else { return }
      CFRunLoopObserverInvalidate(runLoopObserver)
      self.runLoopObserver = nil
    }

    private static func endTheTopmostModalIfAsked() {
      guard
        let topmostWindow = NSApplication.shared.modalWindow,
        let index = windowsToEnd.firstIndex(where: { $0.window === topmostWindow })
      else { return }
      let end = windowsToEnd.remove(at: index).end
      if windowsToEnd.isEmpty {
        stopObserving()
      }
      endingWindows.append(topmostWindow)
      // NB: Ended from a main-queue block, the way the binding ends a modal, rather than from
      //     inside the run loop's observer callout.
      DispatchQueue.main.async {
        MainActor._assumeIsolated {
          end()
        }
      }
    }
  }

#endif
