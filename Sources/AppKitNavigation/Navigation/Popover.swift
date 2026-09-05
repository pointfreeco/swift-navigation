#if canImport(AppKit) && !targetEnvironment(macCatalyst)

public import AppKit

@MainActor
fileprivate final class _PopoverPresentation: NSObject, PopoverContent {
  let popover: NSPopover

  init(
    viewController: NSViewController,
    behavior: NSPopover.Behavior,
    animates: Bool
  ) {
    let popover = NSPopover()
    popover.contentViewController = viewController
    popover.behavior = behavior
    popover.animates = animates
    self.popover = popover
    super.init()
  }
}

private typealias PopoverObserver = NavigationObserver<NSView, _PopoverPresentation>

@MainActor
private let popoverObserverKey = malloc(1)!

extension NSView {
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
    _popover(
      isPresented: isPresented,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

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
    _popover(
      item: item,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

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
    _popover(
      item: item,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @discardableResult
  public func popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    relativeTo rect: NSRect = .zero,
    preferredEdge: NSRectEdge = .minY,
    behavior: NSPopover.Behavior = .transient,
    animates: Bool = true,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: id,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @discardableResult
  public func popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    relativeTo rect: NSRect = .zero,
    preferredEdge: NSRectEdge = .minY,
    behavior: NSPopover.Behavior = .transient,
    animates: Bool = true,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: id,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }
}

extension NSView {
  @discardableResult
  fileprivate func _popover(
    isPresented: UIBinding<Bool>,
    relativeTo rect: NSRect,
    preferredEdge: NSRectEdge,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: isPresented.toOptionalUnit,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss
    ) { _ in content() }
  }

  @discardableResult
  fileprivate func _popover<Item: Identifiable>(
    item: UIBinding<Item?>,
    relativeTo rect: NSRect,
    preferredEdge: NSRectEdge,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: \.id,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @_disfavoredOverload
  @discardableResult
  fileprivate func _popover<Item: Identifiable>(
    item: UIBinding<Item?>,
    relativeTo rect: NSRect,
    preferredEdge: NSRectEdge,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: \.id,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @discardableResult
  fileprivate func _popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    relativeTo rect: NSRect,
    preferredEdge: NSRectEdge,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: id,
      relativeTo: rect,
      preferredEdge: preferredEdge,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss
    ) {
      content($0.wrappedValue)
    }
  }

  @discardableResult
  fileprivate func _popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    relativeTo rect: NSRect,
    preferredEdge: NSRectEdge,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSViewController
  ) -> ObserveToken {
    _popover(item: item, id: id) { binding in
      _PopoverPresentation(
        viewController: content(binding),
        behavior: behavior,
        animates: animates
      )
    } beginPopover: { [weak self] presentation, _ in
      guard let self else { return }
      presentation.appKitNavigationShowPopover(
        relativeTo: rect,
        of: self,
        preferredEdge: preferredEdge
      )
    } endPopover: { presentation, _ in
      presentation.appKitNavigationClosePopover()
      onDismiss?()
    }
  }

  private func _popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    content: @escaping (UIBinding<Item>) -> _PopoverPresentation,
    beginPopover: @escaping (
      _ child: _PopoverPresentation,
      _ transaction: UITransaction
    ) -> Void,
    endPopover: @escaping (
      _ child: _PopoverPresentation,
      _ transaction: UITransaction
    ) -> Void
  ) -> ObserveToken {
    let popoverObserver = popoverObserver()
    return popoverObserver.observe(
      item: item,
      id: { $0[keyPath: id] },
      content: content,
      begin: beginPopover,
      end: endPopover
    )
  }

  private func popoverObserver() -> PopoverObserver {
    if let observer = objc_getAssociatedObject(self, popoverObserverKey) as? PopoverObserver {
      return observer
    } else {
      let observer = PopoverObserver(owner: self)
      objc_setAssociatedObject(
        self,
        popoverObserverKey,
        observer,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      return observer
    }
  }
}

extension Navigated where Content: PopoverContent {
  func clearup() {
    content?.appKitNavigationClosePopover()
  }
}

@available(macOS 14.0, *)
private typealias ToolbarItemPopoverObserver = NavigationObserver<NSToolbarItem, _PopoverPresentation>

@MainActor
private let toolbarItemPopoverObserverKey = malloc(1)!

@available(macOS 14.0, *)
extension NSToolbarItem {
  @discardableResult
  public func popover(
    isPresented: UIBinding<Bool>,
    behavior: NSPopover.Behavior = .transient,
    animates: Bool = true,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSViewController
  ) -> ObserveToken {
    _popover(
      isPresented: isPresented,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @discardableResult
  public func popover<Item: Identifiable>(
    item: UIBinding<Item?>,
    behavior: NSPopover.Behavior = .transient,
    animates: Bool = true,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @_disfavoredOverload
  @discardableResult
  public func popover<Item: Identifiable>(
    item: UIBinding<Item?>,
    behavior: NSPopover.Behavior = .transient,
    animates: Bool = true,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @discardableResult
  public func popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    behavior: NSPopover.Behavior = .transient,
    animates: Bool = true,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: id,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @discardableResult
  public func popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    behavior: NSPopover.Behavior = .transient,
    animates: Bool = true,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: id,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }
}

@available(macOS 14.0, *)
extension NSToolbarItem {
  @discardableResult
  fileprivate func _popover(
    isPresented: UIBinding<Bool>,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: isPresented.toOptionalUnit,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss
    ) { _ in content() }
  }

  @discardableResult
  fileprivate func _popover<Item: Identifiable>(
    item: UIBinding<Item?>,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: \.id,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @_disfavoredOverload
  @discardableResult
  fileprivate func _popover<Item: Identifiable>(
    item: UIBinding<Item?>,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: \.id,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss,
      content: content
    )
  }

  @discardableResult
  fileprivate func _popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken {
    _popover(
      item: item,
      id: id,
      behavior: behavior,
      animates: animates,
      onDismiss: onDismiss
    ) {
      content($0.wrappedValue)
    }
  }

  @discardableResult
  fileprivate func _popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    behavior: NSPopover.Behavior,
    animates: Bool,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSViewController
  ) -> ObserveToken {
    _popover(item: item, id: id) { binding in
      _PopoverPresentation(
        viewController: content(binding),
        behavior: behavior,
        animates: animates
      )
    } beginPopover: { [weak self] presentation, _ in
      guard let self else { return }
      presentation.appKitNavigationShowPopover(relativeTo: self)
    } endPopover: { presentation, _ in
      presentation.appKitNavigationClosePopover()
      onDismiss?()
    }
  }

  private func _popover<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    content: @escaping (UIBinding<Item>) -> _PopoverPresentation,
    beginPopover: @escaping (
      _ child: _PopoverPresentation,
      _ transaction: UITransaction
    ) -> Void,
    endPopover: @escaping (
      _ child: _PopoverPresentation,
      _ transaction: UITransaction
    ) -> Void
  ) -> ObserveToken {
    let popoverObserver = popoverObserver()
    return popoverObserver.observe(
      item: item,
      id: { $0[keyPath: id] },
      content: content,
      begin: beginPopover,
      end: endPopover
    )
  }

  private func popoverObserver() -> ToolbarItemPopoverObserver {
    if let observer = objc_getAssociatedObject(self, toolbarItemPopoverObserverKey) as? ToolbarItemPopoverObserver {
      return observer
    } else {
      let observer = ToolbarItemPopoverObserver(owner: self)
      objc_setAssociatedObject(
        self,
        toolbarItemPopoverObserverKey,
        observer,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      return observer
    }
  }
}

#endif
