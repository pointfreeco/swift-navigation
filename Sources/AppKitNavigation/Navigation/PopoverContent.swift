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
    // `Navigated` holds `self` weakly, and `NSPopover` does not retain its
    // `PopoverContent` host, so we must keep `self` alive through the close
    // subscription. Otherwise `onEndNavigation` runs on a deallocated `self`
    // and the binding is never reset, leaving the popover unable to reopen.
    PopoverPresentationsObserver.shared.observePopover(popover) { [self] in
      self.onEndNavigation?()
    }
    popover.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
  }

  @available(macOS 14.0, *)
  func appKitNavigationShowPopover(relativeTo toolbarItem: NSToolbarItem) {
    PopoverPresentationsObserver.shared.observePopover(popover) { [self] in
      self.onEndNavigation?()
    }
    popover.show(relativeTo: toolbarItem)
  }

  func appKitNavigationClosePopover() {
    popover.close()
  }
}

#endif
