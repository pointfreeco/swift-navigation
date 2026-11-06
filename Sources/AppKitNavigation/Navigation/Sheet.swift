#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  public import AppKit

  extension NSWindow {
    /// Attaches a window, an alert, or a save or open panel to this window as a sheet while a
    /// binding to a Boolean value you provide is true.
    ///
    /// Like SwiftUI's `sheet(isPresented:onDismiss:content:)`, but for AppKit. Setting the binding
    /// to `false` ends the sheet. When the user ends it — a button that ends the sheet, a button of
    /// the alert, the panel's Cancel button — the binding is set to `false`. A sheet set to show
    /// before this window is on screen waits until it is; one set to show while this window
    /// already has a sheet is queued by AppKit until that sheet ends.
    ///
    /// To present a view controller as a sheet, use
    /// ``AppKit/NSViewController/present(isPresented:style:onDismiss:content:)`` with the
    /// ``AppKit/NSViewController/TransitionStyle/sheet`` style.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to attach the sheet.
    ///   - onDismiss: The closure to execute once the sheet has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to attach.
    /// - Returns: A token that stops following the binding once cancelled. An attached sheet then
    ///   stays until the user ends it.
    @discardableResult
    public func sheet<Content: ModalContent>(
      isPresented: UIBinding<Bool>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> Content
    ) -> ObserveToken {
      bindPresentation(
        SheetStyle<Content>(parentWindow: self),
        item: isPresented.toOptionalUnit,
        id: { $0.id },
        onDismiss: onDismiss
      ) { _ in
        content()
      }
    }

    /// Attaches a window, an alert, or a save or open panel to this window as a sheet while a
    /// binding to an optional item holds a value.
    ///
    /// The sheet behaves as with ``sheet(isPresented:onDismiss:content:)``. If the item's identity
    /// changes, the sheet ends, and once it has left the screen, a sheet for the new item is
    /// attached.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet. While it holds a value,
    ///     the value is passed to `content`. When the user ends the sheet, the binding is set to
    ///     `nil`.
    ///   - onDismiss: The closure to execute once the sheet has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to attach for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func sheet<Item: Identifiable, Content: ModalContent>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> Content
    ) -> ObserveToken {
      bindPresentation(
        SheetStyle<Content>(parentWindow: self), item: item, id: { $0.id }, onDismiss: onDismiss
      ) {
        content($0.wrappedValue)
      }
    }

    /// Attaches a window, an alert, or a save or open panel to this window as a sheet while a
    /// binding to an optional item holds a value, passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user ends the sheet, the
    ///     binding is set to `nil`.
    ///   - onDismiss: The closure to execute once the sheet has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to attach for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func sheet<Item: Identifiable, Content: ModalContent>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
      bindPresentation(
        SheetStyle<Content>(parentWindow: self),
        item: item,
        id: { $0.id },
        onDismiss: onDismiss,
        content: content
      )
    }

    /// Attaches a window, an alert, or a save or open panel to this window as a sheet while a
    /// binding to an optional item holds a value, telling items apart by the identifier at a key
    /// path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet. While it holds a value,
    ///     the value is passed to `content`. When the user ends the sheet, the binding is set to
    ///     `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the sheet ends, and once it
    ///     has left the screen, a sheet for the new item is attached.
    ///   - onDismiss: The closure to execute once the sheet has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to attach for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func sheet<Item, Identifier: Hashable, Content: ModalContent>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> Content
    ) -> ObserveToken {
      bindPresentation(
        SheetStyle<Content>(parentWindow: self),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss
      ) {
        content($0.wrappedValue)
      }
    }

    /// Attaches a window, an alert, or a save or open panel to this window as a sheet while a
    /// binding to an optional item holds a value, telling items apart by the identifier at a key
    /// path and passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user ends the sheet, the
    ///     binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the sheet ends, and once it
    ///     has left the screen, a sheet for the new item is attached.
    ///   - onDismiss: The closure to execute once the sheet has ended and left the screen.
    ///   - content: A closure that returns the window, alert or panel to attach for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func sheet<Item, Identifier: Hashable, Content: ModalContent>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
      bindPresentation(
        SheetStyle<Content>(parentWindow: self),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss,
        content: content
      )
    }
  }

  /// Attaches content to a window as a sheet.
  @MainActor
  private struct SheetStyle<Content: ModalContent>: PresentationStyle {
    weak var parentWindow: NSWindow?

    func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
      RunLoopWait.until(
        { [weak parentWindow] in parentWindow?.isVisible == true },
        then: body
      )
    }

    func begin(
      _ content: Content,
      transaction: UITransaction,
      didEnd: @escaping @MainActor () -> Void
    ) {
      guard let parentWindow else {
        didEnd()
        return
      }
      let sheetWindow = content._appKitNavigationWindow
      content._appKitNavigationBeginSheet(attachedTo: parentWindow) {
        // NB: The completion handler runs as the sheet starts to leave, while it is still on
        //     screen.
        _ = RunLoopWait.until({ !sheetWindow.isVisible }, then: didEnd)
      }
    }

    func end(_ content: Content, transaction: UITransaction) {
      let sheetWindow = content._appKitNavigationWindow
      // NB: A sheet still queued behind another one has no sheet parent yet.
      (sheetWindow.sheetParent ?? parentWindow)?.endSheet(sheetWindow)
    }
  }

#endif
