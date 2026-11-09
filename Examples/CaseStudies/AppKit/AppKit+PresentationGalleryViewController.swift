#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class PresentationGalleryViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Presentation styles"
  let readMe = """
  This case study shows every way AppKitNavigation presents content from state. A window, an \
  alert or a save panel runs modally, or is attached to a window as a sheet; a window can also be \
  shown in a modal session, which takes the app's input without blocking. A view or a toolbar \
  item shows a popover, and a view controller presents another one as a sheet, in a modal window \
  or in a popover.

  Every presentation is driven by the model alone: setting its state presents the content, \
  clearing it dismisses the content, and dismissing the content yourself clears the state. The \
  log lists each 'onDismiss' call, which comes once the content has left the screen.
  """
  @UIBindable var model = Model()
  private var documentWindow: NSWindow?
  private let toolbarDelegate = InfoToolbarDelegate()

  override func viewDidLoad() {
    super.viewDidLoad()

    let modalWindowButton = makeButton("Run a window modally") { [weak self] in
      self?.model.isModalWindowPresented = true
    }
    let modalAlertButton = makeButton("Run an alert modally") { [weak self] in
      self?.model.modalAlert = .discardChanges
    }
    let modalSessionButton = makeButton("Show a window in a modal session") { [weak self] in
      self?.model.isModalSessionPresented = true
    }
    let popoverButton = makeButton("Show a popover from this button") { [weak self] in
      self?.model.isPopoverPresented = true
    }
    let viewControllerSheetButton = makeButton("Present as a sheet") { [weak self] in
      self?.model.isViewControllerSheetPresented = true
    }
    let viewControllerWindowButton = makeButton("Present in a modal window") { [weak self] in
      self?.model.isViewControllerWindowPresented = true
    }
    let viewControllerPopoverButton = makeButton("Present in a popover") { [weak self] in
      self?.model.isViewControllerPopoverPresented = true
    }
    let documentWindowButton = makeButton("Open a document window") { [weak self] in
      self?.openDocumentWindow()
    }
    let logLabel = NSTextField(wrappingLabelWithString: "")
    logLabel.textColor = .secondaryLabelColor

    addColumn(
      of: [
        makeSectionLabel("Windows, alerts and panels"),
        modalWindowButton,
        modalAlertButton,
        modalSessionButton,
        documentWindowButton,
        makeSectionLabel("Popovers"),
        popoverButton,
        makeSectionLabel("View controllers"),
        viewControllerSheetButton,
        viewControllerWindowButton,
        viewControllerPopoverButton,
        makeSectionLabel("onDismiss log"),
        logLabel,
      ],
      to: view
    )

    observe { [unowned self] in
      logLabel.stringValue = model.log.isEmpty ? "Nothing dismissed yet." : model.log.joined(separator: "\n")
    }

    // MARK: Modals

    modal(isPresented: $model.isModalWindowPresented, onDismiss: { [weak self] in
      self?.model.record("Modal window")
    }) { [unowned self] in
      makeWindow(
        title: "Modal window",
        message: "This window runs modally. Close it from its title bar, or with the button.",
        buttons: [
          makeButton("Close") { [weak self] in
            self?.model.isModalWindowPresented = false
          }
        ]
      )
    }

    modal(item: $model.modalAlert, onDismiss: { [weak self] in
      self?.model.record("Modal alert")
    }) { [unowned self] alert in
      NSAlert(state: alert) { [weak self] action in
        self?.model.record("Modal alert action: \(action.map { "\($0)" } ?? "cancel")")
      }
    }

    modalSession(isPresented: $model.isModalSessionPresented, onDismiss: { [weak self] in
      self?.model.record("Modal session window")
    }) { [unowned self] in
      makeWindow(
        title: "Modal session",
        message: "This window is in a modal session: it takes the app's input, yet nothing waits for it.",
        buttons: [
          makeButton("Close") { [weak self] in
            self?.model.isModalSessionPresented = false
          }
        ]
      )
    }

    // MARK: Popovers

    popoverButton.popover(
      isPresented: $model.isPopoverPresented,
      preferredEdge: .maxX,
      onDismiss: { [weak self] in self?.model.record("Popover from a button") }
    ) {
      MessageViewController(message: "A popover anchored to a button. Click outside it to close it.")
    }

    // MARK: View controllers

    present(isPresented: $model.isViewControllerSheetPresented, style: .sheet, onDismiss: { [weak self] in
      self?.model.record("View controller sheet")
    }) {
      MessageViewController(message: "A view controller presented as a sheet.")
    }

    present(isPresented: $model.isViewControllerWindowPresented, style: .modalWindow, onDismiss: { [weak self] in
      self?.model.record("View controller modal window")
    }) {
      MessageViewController(message: "A view controller presented in a modal window.")
    }

    present(
      isPresented: $model.isViewControllerPopoverPresented,
      style: .popover(
        rect: viewControllerPopoverButton.bounds,
        view: viewControllerPopoverButton,
        preferredEdge: .maxX,
        behavior: .transient
      ),
      onDismiss: { [weak self] in self?.model.record("View controller popover") }
    ) {
      MessageViewController(message: "A view controller presented in a popover.")
    }
  }

  override func viewDidDisappear() {
    super.viewDidDisappear()
    documentWindow?.close()
    documentWindow = nil
  }

  /// Opens a window of the case study's own: sheets attach to it, and its toolbar item shows a
  /// popover.
  private func openDocumentWindow() {
    if let documentWindow {
      documentWindow.makeKeyAndOrderFront(nil)
      return
    }
    let window = makeWindow(
      title: "Document",
      message: "Sheets attach to this window, and its toolbar item shows a popover.",
      buttons: [
        makeButton("Window sheet") { [weak self] in
          self?.model.isWindowSheetPresented = true
        },
        makeButton("Alert sheet") { [weak self] in
          self?.model.alertSheet = .discardChanges
        },
        makeButton("Save panel sheet") { [weak self] in
          self?.model.isSavePanelSheetPresented = true
        },
      ]
    )
    toolbarDelegate.infoItem.addAction { [weak self] _ in
      self?.model.isToolbarPopoverPresented.toggle()
    }
    let toolbar = NSToolbar(identifier: "PresentationGallery.Document")
    toolbar.delegate = toolbarDelegate
    window.toolbar = toolbar

    // NB: Set up before the window is on screen: a sheet waits until its window is.
    window.sheet(isPresented: $model.isWindowSheetPresented, onDismiss: { [weak self] in
      self?.model.record("Window sheet")
    }) { [unowned self] in
      makeWindow(
        title: "Sheet",
        message: "A window attached as a sheet.",
        buttons: [
          makeButton("Done") { [weak self] in
            self?.model.isWindowSheetPresented = false
          }
        ]
      )
    }
    window.sheet(item: $model.alertSheet, onDismiss: { [weak self] in
      self?.model.record("Alert sheet")
    }) { [unowned self] alert in
      NSAlert(state: alert) { [weak self] action in
        self?.model.record("Alert sheet action: \(action.map { "\($0)" } ?? "cancel")")
      }
    }
    window.sheet(isPresented: $model.isSavePanelSheetPresented, onDismiss: { [weak self] in
      guard let self else { return }
      model.record("Save panel sheet, chose \(model.savedURL?.lastPathComponent ?? "nothing")")
    }) { [unowned self] in
      NSSavePanel(url: $model.savedURL)
    }
    toolbarDelegate.infoItem.popover(
      isPresented: $model.isToolbarPopoverPresented,
      onDismiss: { [weak self] in self?.model.record("Popover from a toolbar item") }
    ) {
      MessageViewController(message: "A popover anchored to a toolbar item.")
    }

    window.makeKeyAndOrderFront(nil)
    documentWindow = window
  }

  @Observable
  class Model {
    var isModalWindowPresented = false
    var modalAlert: AlertState<AlertAction>?
    var isModalSessionPresented = false
    var isPopoverPresented = false
    var isViewControllerSheetPresented = false
    var isViewControllerWindowPresented = false
    var isViewControllerPopoverPresented = false
    var isWindowSheetPresented = false
    var alertSheet: AlertState<AlertAction>?
    var isSavePanelSheetPresented = false
    var savedURL: URL?
    var isToolbarPopoverPresented = false
    var log: [String] = []

    enum AlertAction {
      case discard
    }

    func record(_ event: String) {
      log = Array((log + [event]).suffix(8))
    }
  }
}

extension AlertState where Action == PresentationGalleryViewController.Model.AlertAction {
  static var discardChanges: Self {
    AlertState {
      TextState("Discard the changes?")
    } actions: {
      ButtonState(role: .destructive, action: .discard) {
        TextState("Discard")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    } message: {
      TextState("They can't be recovered.")
    }
  }
}

/// Provides the document window's toolbar, which holds a single Info item.
@MainActor
private final class InfoToolbarDelegate: NSObject, NSToolbarDelegate {
  let infoItem: NSToolbarItem = {
    let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("Info"))
    item.label = "Info"
    item.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "Info")
    return item
  }()

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    itemIdentifier == infoItem.itemIdentifier ? infoItem : nil
  }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [infoItem.itemIdentifier]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [infoItem.itemIdentifier]
  }
}

#Preview {
  PresentationGalleryViewController()
}
#endif
