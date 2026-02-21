#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation
import SwiftUI

class WiFiSettingsViewController: XiblessViewController<NSScrollView>, AppKitCaseStudy {
    let caseStudyTitle = "Wi-Fi Settings"
    let readMe = """
    This demo shows how to built a moderately complex feature using the tools of the library. \
    There are multiple features that communicate with each other, there are multiple navigation \
    patterns, and the root feature has a complex collection view that updates dynamically.
    """
    let isPresentedInSheet = true

    @UIBindable var model: WiFiSettingsModel

    var dataSource: NSCollectionViewDiffableDataSource<Section, Item>!

    let collectionView = NSCollectionView()

    init(model: WiFiSettingsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.autoresizingMask = [.width, .height]
        contentView.documentView = collectionView
        let collectionViewLayout = NSCollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(sectionIndex == 0 ? 60 : 44))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 0, leading: sectionIndex == 0 ? 10 : 30, bottom: 0, trailing: 10)
            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(sectionIndex == 0 ? 60 : 44))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            let decorationItem = NSCollectionLayoutDecorationItem.background(elementKind: NSCollectionView.DecorationElementKind.background)
            decorationItem.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            section.decorationItems = [decorationItem]
            return section
        }
        collectionViewLayout.register(WiFiSettingsSectionBackgroundView.self, forDecorationViewOfKind: .background)
        let configuration = NSCollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 20
        collectionViewLayout.configuration = configuration
        collectionView.collectionViewLayout = collectionViewLayout
        collectionView.register(WiFiSettingsSwitchViewItem.self, forItemWithIdentifier: .init(WiFiSettingsSwitchViewItem.self))
        collectionView.register(WiFiSettingsConnectedNetworkViewItem.self, forItemWithIdentifier: .init(WiFiSettingsConnectedNetworkViewItem.self))
        collectionView.register(WiFiSettingsFoundedNetworkViewItem.self, forItemWithIdentifier: .init(WiFiSettingsFoundedNetworkViewItem.self))

        dataSource = NSCollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return nil }
            switch item {
            case .isOn:
                let switchViewItem = collectionView.makeItem(withIdentifier: .init(WiFiSettingsSwitchViewItem.self), for: indexPath) as! WiFiSettingsSwitchViewItem
                switchViewItem.switchView.bind(isOn: $model.isOn)
                return switchViewItem
            case let .selectedNetwork(networkID):
                guard let network = model.foundNetworks.first(where: { $0.id == networkID })
                else { return nil }
                let connectedViewItem = collectionView.makeItem(withIdentifier: .init(WiFiSettingsConnectedNetworkViewItem.self), for: indexPath) as! WiFiSettingsConnectedNetworkViewItem
                connectedViewItem.nameLabel.stringValue = network.name
                connectedViewItem.securedIconImageView.isHidden = !network.isSecured
                connectedViewItem.wifiIconImageView.image = NSImage(systemSymbolName: "wifi", variableValue: network.connectivity, accessibilityDescription: nil)
                connectedViewItem.detailButton.addAction { [weak self] _ in
                    guard let self else { return }
                    self.model.infoButtonTapped(network: network)
                }
                return connectedViewItem
            case let .foundNetwork(network):
                let foundedViewItem = collectionView.makeItem(withIdentifier: .init(WiFiSettingsFoundedNetworkViewItem.self), for: indexPath) as! WiFiSettingsFoundedNetworkViewItem
                foundedViewItem.titleLabel.stringValue = network.name
                foundedViewItem.securedIconImageView.isHidden = !network.isSecured
                foundedViewItem.wifiIconImageView.image = NSImage(systemSymbolName: "wifi", variableValue: network.connectivity, accessibilityDescription: nil)
                foundedViewItem.connectButton.addAction { [weak self] _ in
                    guard let self else { return }
                    self.model.networkTapped(network)
                }
                return foundedViewItem
            }
        }

        observe { [weak self] in
            guard let self else { return }
            dataSource.apply(
                NSDiffableDataSourceSnapshot(model: model),
                animatingDifferences: true
            )
        }

        modalSession(item: $model.destination.connect) { model in
            let panel = NSPanel(contentViewController: ConnectToNetworkViewController(model: model))
            panel.styleMask = [.titled]
            panel.title = ""
            panel.animationBehavior = .none
            return panel
        }

        present(item: $model.destination.detail, style: .sheet) { model in
            let vc = NetworkDetailViewController(model: model)
            vc.preferredContentSize = .init(width: 300, height: 200)
            return vc
        }
    }
}

#Preview {
    let model = WiFiSettingsModel(foundNetworks: .mocks)
    return NSViewControllerRepresenting {
        WiFiSettingsViewController(model: model)
    }
    .task {
        while true {
            try? await Task.sleep(for: .seconds(1))
            guard Bool.random() else { continue }
            if Bool.random() {
                guard let randomIndex = (0 ..< model.foundNetworks.count).randomElement()
                else { continue }
                if model.foundNetworks[randomIndex].id != model.selectedNetworkID {
                    model.foundNetworks.remove(at: randomIndex)
                }
            } else {
                model.foundNetworks.append(
                    Network(
                        name: goofyWiFiNames.randomElement()!,
                        isSecured: !(1 ... 1000).randomElement()!.isMultiple(of: 5),
                        connectivity: Double((1 ... 100).randomElement()!) / 100
                    )
                )
            }
        }
    }
}

extension NSCollectionView.DecorationElementKind {
    static let background = "BackgroundKind"
}

class WiFiSettingsSectionBackgroundView: NSBox, NSCollectionViewElement {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        titlePosition = .noTitle
    }
}

class XiblessCollectionViewItem<View: NSView>: NSCollectionViewItem {
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = View()
    }
}

class WiFiSettingsSwitchViewItem: XiblessCollectionViewItem<NSView> {
    let iconImageView = NSImageView()

    let titleLabel = NSTextField(labelWithString: "Wi-Fi")

    let switchView = NSSwitch()
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let stackView = NSStackView()
        stackView.addView(iconImageView, in: .leading)
        stackView.addView(titleLabel, in: .leading)
        stackView.addView(switchView, in: .trailing)
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 15
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        let image = NSImage(systemSymbolName: "wifi", accessibilityDescription: "Wi-Fi")!
        iconImageView.image = image.withSymbolConfiguration(.init(pointSize: 15, weight: .regular))
        iconImageView.wantsLayer = true
        iconImageView.layer?.cornerRadius = 5
        iconImageView.layer?.backgroundColor = NSColor.systemBlue.cgColor
        iconImageView.contentTintColor = .white
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
        ])
        switchView.controlSize = .large
    }
}

class WiFiSettingsConnectedNetworkViewItem: XiblessCollectionViewItem<NSView> {
    let nameLabel = NSTextField(labelWithString: "WiFi Name")
    let statusButton = NSButton()
    let securedIconImageView = NSImageView(systemSymbolName: "lock.fill")
    let wifiIconImageView = NSImageView(systemSymbolName: "wifi")
    let detailButton = NSButton(title: "Detail...", target: nil, action: nil)
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 15
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let textStackView = NSStackView()
        textStackView.orientation = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 3
        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(statusButton)
        stackView.addView(textStackView, in: .leading)
        stackView.addView(securedIconImageView, in: .trailing)
        stackView.addView(wifiIconImageView, in: .trailing)
        stackView.addView(detailButton, in: .trailing)

        statusButton.isBordered = false
        statusButton.image = NSImage(named: NSImage.statusAvailableName)
        (statusButton.cell as! NSButtonCell).highlightsBy = []
        statusButton.attributedTitle = NSAttributedString(string: "Connected", attributes: [
            .foregroundColor: NSColor.secondaryLabelColor,
        ])
        statusButton.imagePosition = .imageLeft
        securedIconImageView.contentTintColor = .labelColor
        wifiIconImageView.contentTintColor = .labelColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        detailButton.removeAllActions()
    }
}

class WiFiSettingsFoundedNetworkViewItem: XiblessCollectionViewItem<NSView> {
    let selectedIconImageView = NSImageView(systemSymbolName: "checkmark")
    let titleLabel = NSTextField(labelWithString: "WiFi Name")
    let securedIconImageView = NSImageView(systemSymbolName: "lock.fill")
    let wifiIconImageView = NSImageView(systemSymbolName: "wifi")
    let connectButton = NSButton(title: "Connect", target: nil, action: nil)

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 10
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
//        stackView.addView(selectedIconImageView, in: .leading)
        stackView.addView(titleLabel, in: .leading)
        stackView.addView(connectButton, in: .trailing)
        stackView.addView(securedIconImageView, in: .trailing)
        stackView.addView(wifiIconImageView, in: .trailing)
        selectedIconImageView.symbolConfiguration = .init(pointSize: 12, weight: .heavy)
        selectedIconImageView.contentTintColor = .labelColor
        securedIconImageView.contentTintColor = .labelColor
        wifiIconImageView.contentTintColor = .labelColor
        connectButton.isHidden = true
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        view.trackingAreas.forEach(view.removeTrackingArea(_:))
        view.addTrackingArea(.init(rect: view.bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .assumeInside], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        connectButton.isHidden = false
    }

    override func mouseMoved(with event: NSEvent) {
        connectButton.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        connectButton.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        connectButton.removeAllActions()
    }
}

@available(macOS 14.0, *)
#Preview {
    let item = WiFiSettingsConnectedNetworkViewItem()
    item.preferredContentSize = .init(width: 500, height: 200)
    return item
}

extension NSUserInterfaceItemIdentifier {
    init(_ anyClass: AnyClass) {
        self.init(rawValue: "\(anyClass)")
    }
}

extension NSImageView {
    convenience init(systemSymbolName: String) {
        self.init()
        self.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil)
    }

    convenience init(systemSymbolName: String, variableValue: Double) {
        self.init()
        self.image = NSImage(systemSymbolName: systemSymbolName, variableValue: variableValue, accessibilityDescription: nil)
    }
}

extension NSButton {
    convenience init(systemSymbolName: String) {
        self.init()
        self.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil)
    }
}

#endif
