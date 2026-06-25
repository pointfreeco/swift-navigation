#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
protocol PopoverContent: NavigationContent {
  var popover: NSPopover { get }
  func appKitNavigationShowPopover(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge)
  func appKitNavigationClosePopover()
}

extension PopoverContent {
  func appKitNavigationShowPopover(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge) {
    PopoverPresentationsObserver.shared.observePopover(popover) { [weak self] in
      self?.onEndNavigation?()
    }
    popover.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
  }

  @available(macOS 14.0, *)
  func appKitNavigationShowPopover(relativeTo toolbarItem: NSToolbarItem) {
    PopoverPresentationsObserver.shared.observePopover(popover) { [weak self] in
      self?.onEndNavigation?()
    }
    popover.show(relativeTo: toolbarItem)
  }

  func appKitNavigationClosePopover() {
    popover.close()
  }
}

#endif
