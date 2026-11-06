#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  public import AppKit

  extension NSView {
    /// Shows a view controller in a popover anchored to this view while a binding to a Boolean
    /// value you provide is true.
    ///
    /// Like SwiftUI's `popover(isPresented:attachmentAnchor:arrowEdge:content:)`, but for AppKit.
    /// Setting the binding to `false` closes the popover. When the user closes it — by clicking
    /// outside a transient popover, or by pressing Escape — the binding is set to `false`. A
    /// popover set to show before this view is in a window on screen waits until it is.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to show the popover.
    ///   - rect: The rectangle, in this view's coordinates, that the popover points at. The
    ///     default, `.zero`, points at the whole view.
    ///   - preferredEdge: The edge of `rect` the popover prefers to show from.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show in the popover.
    /// - Returns: A token that stops following the binding once cancelled. A popover that is shown
    ///   then stays until the user closes it.
    @discardableResult
    public func popover(
      isPresented: UIBinding<Bool>,
      relativeTo rect: NSRect = .zero,
      preferredEdge: NSRectEdge = .minY,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(rect: rect, preferredEdge: preferredEdge, behavior: behavior, animates: animates),
        item: isPresented.toOptionalUnit,
        id: { $0.id },
        onDismiss: onDismiss
      ) { _ in
        PopoverContent(viewController: content())
      }
    }

    /// Shows a view controller in a popover anchored to this view while a binding to an optional
    /// item holds a value.
    ///
    /// The popover behaves as with
    /// ``popover(isPresented:relativeTo:preferredEdge:behavior:animates:onDismiss:content:)``. If
    /// the item's identity changes, the popover closes, and once it has, a popover for the new
    /// item shows.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     the value is passed to `content`. When the user closes the popover, the binding is set
    ///     to `nil`.
    ///   - rect: The rectangle, in this view's coordinates, that the popover points at. The
    ///     default, `.zero`, points at the whole view.
    ///   - preferredEdge: The edge of `rect` the popover prefers to show from.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func popover<Item: Identifiable>(
      item: UIBinding<Item?>,
      relativeTo rect: NSRect = .zero,
      preferredEdge: NSRectEdge = .minY,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(rect: rect, preferredEdge: preferredEdge, behavior: behavior, animates: animates),
        item: item,
        id: { $0.id },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0.wrappedValue))
      }
    }

    /// Shows a view controller in a popover anchored to this view while a binding to an optional
    /// item holds a value, passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user closes the popover, the
    ///     binding is set to `nil`.
    ///   - rect: The rectangle, in this view's coordinates, that the popover points at. The
    ///     default, `.zero`, points at the whole view.
    ///   - preferredEdge: The edge of `rect` the popover prefers to show from.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func popover<Item: Identifiable>(
      item: UIBinding<Item?>,
      relativeTo rect: NSRect = .zero,
      preferredEdge: NSRectEdge = .minY,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(rect: rect, preferredEdge: preferredEdge, behavior: behavior, animates: animates),
        item: item,
        id: { $0.id },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0))
      }
    }

    /// Shows a view controller in a popover anchored to this view while a binding to an optional
    /// item holds a value, telling items apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     the value is passed to `content`. When the user closes the popover, the binding is set
    ///     to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the popover closes, and
    ///     once it has, a popover for the new item shows.
    ///   - rect: The rectangle, in this view's coordinates, that the popover points at. The
    ///     default, `.zero`, points at the whole view.
    ///   - preferredEdge: The edge of `rect` the popover prefers to show from.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func popover<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      relativeTo rect: NSRect = .zero,
      preferredEdge: NSRectEdge = .minY,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(rect: rect, preferredEdge: preferredEdge, behavior: behavior, animates: animates),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0.wrappedValue))
      }
    }

    /// Shows a view controller in a popover anchored to this view while a binding to an optional
    /// item holds a value, telling items apart by the identifier at a key path and passing the
    /// content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user closes the popover, the
    ///     binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the popover closes, and
    ///     once it has, a popover for the new item shows.
    ///   - rect: The rectangle, in this view's coordinates, that the popover points at. The
    ///     default, `.zero`, points at the whole view.
    ///   - preferredEdge: The edge of `rect` the popover prefers to show from.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func popover<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      relativeTo rect: NSRect = .zero,
      preferredEdge: NSRectEdge = .minY,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(rect: rect, preferredEdge: preferredEdge, behavior: behavior, animates: animates),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0))
      }
    }

    private func popoverStyle(
      rect: NSRect,
      preferredEdge: NSRectEdge,
      behavior: NSPopover.Behavior,
      animates: Bool
    ) -> PopoverStyle<ViewAnchor> {
      PopoverStyle(
        anchor: ViewAnchor(view: self, rect: rect, preferredEdge: preferredEdge),
        behavior: behavior,
        animates: animates
      )
    }
  }

  @available(macOS 14.0, *)
  extension NSToolbarItem {
    /// Shows a view controller in a popover anchored to this toolbar item while a binding to a
    /// Boolean value you provide is true.
    ///
    /// Setting the binding to `false` closes the popover. When the user closes it — by clicking
    /// outside a transient popover, or by pressing Escape — the binding is set to `false`. A
    /// popover set to show before the item's toolbar is on screen waits until it is.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to show the popover.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show in the popover.
    /// - Returns: A token that stops following the binding once cancelled. A popover that is shown
    ///   then stays until the user closes it.
    @discardableResult
    public func popover(
      isPresented: UIBinding<Bool>,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(behavior: behavior, animates: animates),
        item: isPresented.toOptionalUnit,
        id: { $0.id },
        onDismiss: onDismiss
      ) { _ in
        PopoverContent(viewController: content())
      }
    }

    /// Shows a view controller in a popover anchored to this toolbar item while a binding to an
    /// optional item holds a value.
    ///
    /// The popover behaves as with ``popover(isPresented:behavior:animates:onDismiss:content:)``.
    /// If the item's identity changes, the popover closes, and once it has, a popover for the new
    /// item shows.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     the value is passed to `content`. When the user closes the popover, the binding is set
    ///     to `nil`.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func popover<Item: Identifiable>(
      item: UIBinding<Item?>,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(behavior: behavior, animates: animates),
        item: item,
        id: { $0.id },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0.wrappedValue))
      }
    }

    /// Shows a view controller in a popover anchored to this toolbar item while a binding to an
    /// optional item holds a value, passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user closes the popover, the
    ///     binding is set to `nil`.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func popover<Item: Identifiable>(
      item: UIBinding<Item?>,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(behavior: behavior, animates: animates),
        item: item,
        id: { $0.id },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0))
      }
    }

    /// Shows a view controller in a popover anchored to this toolbar item while a binding to an
    /// optional item holds a value, telling items apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     the value is passed to `content`. When the user closes the popover, the binding is set
    ///     to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the popover closes, and
    ///     once it has, a popover for the new item shows.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func popover<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(behavior: behavior, animates: animates),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0.wrappedValue))
      }
    }

    /// Shows a view controller in a popover anchored to this toolbar item while a binding to an
    /// optional item holds a value, telling items apart by the identifier at a key path and
    /// passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. While it holds a value,
    ///     a binding to the value is passed to `content`. When the user closes the popover, the
    ///     binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the popover closes, and
    ///     once it has, a popover for the new item shows.
    ///   - behavior: Whether the popover closes when the user interacts with something else.
    ///   - animates: Whether the popover animates showing and closing. A transaction that disables
    ///     animations turns it off for the change it comes with.
    ///   - onDismiss: The closure to execute once the popover has closed.
    ///   - content: A closure that returns the view controller to show for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func popover<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      behavior: NSPopover.Behavior = .transient,
      animates: Bool = true,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        popoverStyle(behavior: behavior, animates: animates),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss
      ) {
        PopoverContent(viewController: content($0))
      }
    }

    private func popoverStyle(
      behavior: NSPopover.Behavior,
      animates: Bool
    ) -> PopoverStyle<ToolbarItemAnchor> {
      PopoverStyle(
        anchor: ToolbarItemAnchor(toolbarItem: self),
        behavior: behavior,
        animates: animates
      )
    }
  }

  // MARK: - Style

  /// What a popover points at: a view, or a toolbar item.
  @MainActor
  private protocol PopoverAnchor: Sendable {
    /// Whether the anchor is on screen, so that a popover can point at it.
    var isOnScreen: Bool { get }

    func show(_ popover: NSPopover)
  }

  @MainActor
  private struct ViewAnchor: PopoverAnchor {
    weak var view: NSView?
    let rect: NSRect
    let preferredEdge: NSRectEdge

    var isOnScreen: Bool {
      view?.window?.isVisible == true
    }

    func show(_ popover: NSPopover) {
      guard let view else { return }
      popover.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
    }
  }

  @available(macOS 14.0, *)
  @MainActor
  private struct ToolbarItemAnchor: PopoverAnchor {
    weak var toolbarItem: NSToolbarItem?

    var isOnScreen: Bool {
      guard let toolbar = toolbarItem?.toolbar, toolbar.isVisible else { return false }
      return NSApplication.shared.windows.contains { $0.toolbar === toolbar && $0.isVisible }
    }

    func show(_ popover: NSPopover) {
      guard let toolbarItem else { return }
      popover.show(relativeTo: toolbarItem)
    }
  }

  /// A popover shown for one item, and what is needed to tell when it has closed.
  @MainActor
  private final class PopoverContent {
    let popover = NSPopover()
    var closeObserver: NotificationObserver?
    var didEnd: (@MainActor () -> Void)?

    init(viewController: NSViewController) {
      popover.contentViewController = viewController
    }

    /// Reports that the popover has closed, once.
    func finish() {
      closeObserver?.invalidate()
      closeObserver = nil
      let didEnd = didEnd
      self.didEnd = nil
      didEnd?()
    }
  }

  /// Shows content in a popover pointing at an anchor.
  @MainActor
  private struct PopoverStyle<Anchor: PopoverAnchor>: PresentationStyle {
    let anchor: Anchor
    let behavior: NSPopover.Behavior
    let animates: Bool

    func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
      RunLoopWait.until({ [anchor] in anchor.isOnScreen }, then: body)
    }

    func begin(
      _ content: PopoverContent,
      transaction: UITransaction,
      didEnd: @escaping @MainActor () -> Void
    ) {
      let popover = content.popover
      popover.behavior = behavior
      popover.animates = animates && !transaction.appKit.disablesAnimations
      content.didEnd = didEnd
      content.closeObserver = NotificationObserver(
        name: NSPopover.didCloseNotification, object: popover
      ) { [weak content] _ in
        content?.finish()
      }
      anchor.show(popover)
    }

    func end(_ content: PopoverContent, transaction: UITransaction) {
      let popover = content.popover
      guard popover.isShown else {
        // NB: Never got on screen, or is already closing, so no close notification will come.
        content.finish()
        return
      }
      popover.animates = animates && !transaction.appKit.disablesAnimations
      popover.close()
    }
  }

#endif
