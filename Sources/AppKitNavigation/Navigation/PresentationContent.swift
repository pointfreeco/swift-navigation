#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
protocol PresentationContent: NavigationContent {
  func presented(from presentingViewController: NSViewController, style: NSViewController.TransitionStyle)
  func dismiss(from presentingViewController: NSViewController)
}

extension NSViewController: PresentationContent {
  func presented(from presentingViewController: NSViewController, style: TransitionStyle) {
    presentingViewController.present(self, for: style)
  }

  func dismiss(from presentingViewController: NSViewController) {
    presentingViewController.dismiss(self)
  }

  public enum TransitionStyle {
    case sheet
    case modalWindow
    case popover(rect: NSRect, view: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)
    case custom(NSViewControllerPresentationAnimator)
  }

  func present(_ viewControllerToPresent: NSViewController, for style: TransitionStyle) {
    switch style {
    case .sheet:
      presentAsSheet(viewControllerToPresent)
    case .modalWindow:
      presentAsModalWindow(viewControllerToPresent)
    case let .popover(rect, view, preferredEdge, behavior):
      present(viewControllerToPresent, asPopoverRelativeTo: rect, of: view, preferredEdge: preferredEdge, behavior: behavior)
    case let .custom(animator):
      present(viewControllerToPresent, animator: animator)
    }
  }
}

#endif
