#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

// Small pieces the presentation and binding case studies share.

/// A push button that runs `action` when clicked.
@MainActor
func makeButton(_ title: String, action: @escaping () -> Void) -> NSButton {
  let button = NSButton(title: title, target: nil, action: nil)
  button.addAction { _ in action() }
  return button
}

/// A bold label that heads a group of controls.
@MainActor
func makeSectionLabel(_ title: String) -> NSTextField {
  let label = NSTextField(labelWithString: title)
  label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
  return label
}

/// Lays `views` out in a column pinned to the top of `view`, and returns the column.
@MainActor
@discardableResult
func addColumn(of views: [NSView], to view: NSView) -> NSStackView {
  let column = NSStackView(views: views)
  column.orientation = .vertical
  column.alignment = .leading
  column.spacing = 10
  column.translatesAutoresizingMaskIntoConstraints = false
  view.addSubview(column)
  NSLayoutConstraint.activate([
    column.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
    column.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
    column.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
  ])
  return column
}

/// A titled, closable window showing a message above a row of buttons.
@MainActor
func makeWindow(title: String, message: String, buttons: [NSButton]) -> NSWindow {
  let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 380, height: 150),
    styleMask: [.titled, .closable],
    backing: .buffered,
    defer: false
  )
  window.title = title
  window.isReleasedWhenClosed = false

  let messageLabel = NSTextField(wrappingLabelWithString: message)
  let buttonRow = NSStackView(views: buttons)
  buttonRow.orientation = .horizontal
  buttonRow.spacing = 8
  let column = NSStackView(views: [messageLabel, buttonRow])
  column.orientation = .vertical
  column.alignment = .leading
  column.spacing = 16
  column.translatesAutoresizingMaskIntoConstraints = false

  let contentView = NSView()
  contentView.addSubview(column)
  NSLayoutConstraint.activate([
    column.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
    column.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
    column.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
    column.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
    messageLabel.widthAnchor.constraint(equalToConstant: 340),
  ])
  window.contentView = contentView
  window.center()
  return window
}

/// A view controller to present: a message above a row of buttons.
///
/// Its Done button dismisses it the way a user would, through `dismiss(_:)`, so the presentation
/// learns about it from the dismissal and clears its state.
class MessageViewController: XiblessViewController<NSView> {
  private let message: String
  private let extraButtons: [NSButton]

  init(message: String, extraButtons: [NSButton] = []) {
    self.message = message
    self.extraButtons = extraButtons
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let messageLabel = NSTextField(wrappingLabelWithString: message)
    let doneButton = makeButton("Done") { [weak self] in
      self?.dismiss(nil)
    }
    doneButton.keyEquivalent = "\r"
    let buttonRow = NSStackView(views: extraButtons + [doneButton])
    buttonRow.orientation = .horizontal
    buttonRow.spacing = 8
    let column = NSStackView(views: [messageLabel, buttonRow])
    column.orientation = .vertical
    column.alignment = .leading
    column.spacing = 16
    column.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(column)
    NSLayoutConstraint.activate([
      column.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      column.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      column.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      column.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
      messageLabel.widthAnchor.constraint(equalToConstant: 300),
    ])
  }
}
#endif
