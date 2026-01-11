#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation

final class ConnectToNetworkViewController: XiblessViewController<NSView> {
  @UIBindable var model: ConnectToNetworkModel

  init(model: ConnectToNetworkModel) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.frame = .init(origin: .zero, size: .init(width: 450, height: 234))
    let wifiIconImage = NSImageView(systemSymbolName: "wifi")
    wifiIconImage.contentTintColor = .systemBlue
    wifiIconImage.symbolConfiguration = .init(pointSize: 60, weight: .regular)

    let titleLabel = NSTextField(labelWithString: "Enter the password for “\(model.network.name)”")
    titleLabel.font = .boldSystemFont(ofSize: 13)
    let detailLabel = NSTextField(wrappingLabelWithString: "You can also access this Wi-Fi network by sharing the password from a nearby iPhone, iPad, or Mac which has connected to this network and has you in their contacts.")
    detailLabel.font = .systemFont(ofSize: 12)
    let textStackView = NSStackView(views: [
      titleLabel,
      detailLabel,
    ])
    textStackView.orientation = .vertical
    textStackView.alignment = .leading

    let topStackView = NSStackView(views: [
      Spacer(size: .init(width: 15, height: 0)),
      wifiIconImage,
      textStackView,
      HorizontalMaxSpacer(),
    ])
    topStackView.orientation = .horizontal

    let passwordLabel = NSTextField(labelWithString: "Password:")

    let passwordTextField = NSSecureTextField(text: $model.password)
    passwordTextField.bezelStyle = .roundedBezel
    passwordTextField.becomeFirstResponder()
    passwordTextField.placeholderString = "The password is 'blob'"

    let centerStackView = NSStackView(views: [
      HorizontalMaxSpacer(),
      passwordLabel,
      passwordTextField,
    ])
    centerStackView.orientation = .horizontal
    NSLayoutConstraint.activate([
      passwordTextField.widthAnchor.constraint(equalToConstant: 253),
    ])

    let cancelButton = NSButton()
    cancelButton.addAction { [weak self] _ in
      guard let self else { return }
      model.cancelButtonTapped()
    }
    cancelButton.title = "Cancel"

    let joinButton = NSButton()
    joinButton.addAction { [weak self] _ in
      guard let self else { return }
      Task {
        await self.model.joinButtonTapped()
      }
    }
    joinButton.title = "Join"

    let progress = NSProgressIndicator()
    progress.isIndeterminate = true
    progress.style = .spinning
    progress.controlSize = .small
    progress.startAnimation(nil)

    let progressStackView = NSStackView(views: [
      HorizontalMaxSpacer(),
      progress,
    ])

    let bottomStackView = NSStackView(views: [
      HorizontalMaxSpacer(),
      cancelButton,
      joinButton,
    ])
    bottomStackView.orientation = .horizontal

    NSLayoutConstraint.activate([
      joinButton.widthAnchor.constraint(equalToConstant: 70),
      cancelButton.widthAnchor.constraint(equalToConstant: 70),
    ])

    let stack = NSStackView(views: [
      topStackView,
      centerStackView,
      progressStackView,
      bottomStackView,
    ])

    stack.orientation = .vertical
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.edgeInsets = .init(top: 20, left: 0, bottom: 20, right: 20)
    stack.distribution = .equalSpacing
    stack.detachesHiddenViews = false
    view.addSubview(stack)
    progressStackView.isHidden = true
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      stack.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      stack.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
    ])

    observe { [weak self, weak passwordTextField] in
      guard
        let self,
        let passwordTextField
      else { return }

      passwordTextField.isEnabled = !model.isConnecting
      joinButton.isEnabled = !model.isConnecting
      progressStackView.isHidden = !model.isConnecting
    }

    modal(isModaled: $model.incorrectPasswordAlertIsPresented) { [unowned self] in
      let alert = NSAlert()
      alert.messageText = "Incorrect password for “\(model.network.name)”"
      alert.addButton(withTitle: "OK")
      return alert
    }
  }
}

class HorizontalMaxSpacer: NSView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class Spacer: NSView {
  init(size: NSSize) {
    super.init(frame: .zero)
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: size.width),
      heightAnchor.constraint(equalToConstant: size.height),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

#Preview(traits: .fixedLayout(width: 450, height: 262)) {
  let vc = ConnectToNetworkViewController(
    model: ConnectToNetworkModel(
      network: Network(name: "Blob's WiFi")
    )
  )
  vc.preferredContentSize = .init(width: 450, height: 234)
  return vc
}
#endif
