#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  public import AppKit

  /// Content that AppKit shows in a window of its own — a window, an alert, or a save or open
  /// panel — either attached to another window as a sheet, or run as an application-modal window.
  ///
  /// Return a conforming value from the `content` closure of
  /// ``AppKit/NSWindow/sheet(isPresented:onDismiss:content:)`` to attach it as a sheet, or of
  /// ``ObjectiveC/NSObject/modal(isPresented:onDismiss:content:)`` to run it as a modal.
  /// `NSWindow`, and through it every panel, conforms, as does `NSAlert`.
  ///
  /// The requirements are implementation details of AppKitNavigation. Conforming other types is not
  /// supported.
  @MainActor
  public protocol WindowBackedContent: AnyObject {
    /// The window that shows the content.
    @_documentation(visibility: private)
    var _appKitNavigationWindow: NSWindow { get }

    /// Attaches the content to `parentWindow` as a sheet, and calls `completionHandler` once the
    /// sheet has ended.
    @_documentation(visibility: private)
    func _appKitNavigationBeginSheet(
      attachedTo parentWindow: NSWindow,
      completionHandler: @escaping @MainActor () -> Void
    )

    /// Runs the content in an application-modal loop, and returns once the loop has ended.
    @_documentation(visibility: private)
    func _appKitNavigationRunModal()
  }

  extension NSWindow: WindowBackedContent {
    @_documentation(visibility: private)
    public var _appKitNavigationWindow: NSWindow { self }

    @_documentation(visibility: private)
    public func _appKitNavigationBeginSheet(
      attachedTo parentWindow: NSWindow,
      completionHandler: @escaping @MainActor () -> Void
    ) {
      // NB: A save or open panel has to go through its own method. Attached like a plain window,
      //     its Cancel button cannot end the sheet.
      if let savePanel = self as? NSSavePanel {
        savePanel.beginSheetModal(for: parentWindow) { _ in
          completionHandler()
        }
      } else {
        parentWindow.beginSheet(self) { _ in
          completionHandler()
        }
      }
    }

    @_documentation(visibility: private)
    public func _appKitNavigationRunModal() {
      if let savePanel = self as? NSSavePanel {
        _ = savePanel.runModal()
      } else {
        _ = NSApplication.shared.runModal(for: self)
      }
    }
  }

  extension NSAlert: WindowBackedContent {
    @_documentation(visibility: private)
    public var _appKitNavigationWindow: NSWindow { window }

    @_documentation(visibility: private)
    public func _appKitNavigationBeginSheet(
      attachedTo parentWindow: NSWindow,
      completionHandler: @escaping @MainActor () -> Void
    ) {
      beginSheetModal(for: parentWindow) { _ in
        completionHandler()
      }
    }

    @_documentation(visibility: private)
    public func _appKitNavigationRunModal() {
      _ = runModal()
    }
  }

#endif
