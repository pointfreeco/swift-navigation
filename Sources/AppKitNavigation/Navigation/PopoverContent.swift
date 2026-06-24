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

  func appKitNavigationClosePopover() {
    popover.close()
  }
}

#endif
