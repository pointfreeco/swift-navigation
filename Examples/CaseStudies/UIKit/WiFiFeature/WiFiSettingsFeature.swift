import SwiftUI
import UIKitNavigation

@Observable
@MainActor
class WiFiSettingsModel {
  var destination: Destination? {
    didSet { bind() }
  }
  var foundNetworks: [Network]
  var isOn: Bool
  var selectedNetworkID: Network.ID?

  @CasePathable
  enum Destination {
    case connect(ConnectToNetworkModel)
    case detail(NetworkDetailModel)
  }

  init(
    foundNetworks: [Network] = [],
    isOn: Bool = true,
    selectedNetworkID: Network.ID? = nil
  ) {
    self.foundNetworks = foundNetworks
    self.isOn = isOn
    self.selectedNetworkID = selectedNetworkID
    bind()
  }

  private func bind() {
    switch destination {
    case .connect(let model):
      model.onConnect = { [weak self] network in
        guard let self else { return }
        destination = nil
        selectedNetworkID = network.id
      }

    case .detail(let model):
      model.onConfirmForget = { [weak self] in
        guard let self else { return }
        self.destination = nil
        self.selectedNetworkID = nil
      }

    case .none:
      break
    }
  }

  func infoButtonTapped(network: Network) {
    destination = .detail(
      NetworkDetailModel(
        network: network,
        selectedNetworkID: selectedNetworkID
      )
    )
  }

  func networkTapped(_ network: Network) {
    if network.id == selectedNetworkID {
      infoButtonTapped(network: network)
    } else if network.isSecured {
      destination = .connect(ConnectToNetworkModel(network: network))
    } else {
      selectedNetworkID = network.id
    }
  }
}

class WiFiSettingsViewController: UICollectionViewController, UIKitCaseStudy {
  let caseStudyTitle = "Wi-Fi Settings"
  let readMe = """
    This demo shows how to built a moderately complex feature using the tools of the library. \
    There are multiple features that communicate with each other, there are multiple navigation \
    patterns, and the root feature has a complex collection view that updates dynamically.
    """
  let isPresentedInSheet = true

  @UIBindable var model: WiFiSettingsModel
  var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

  init(model: WiFiSettingsModel) {
    self.model = model
    super.init(
      collectionViewLayout: UICollectionViewCompositionalLayout.list(
        using: UICollectionLayoutListConfiguration(appearance: .insetGrouped)
      )
    )
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "Wi-Fi"

    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
      [weak self] cell, indexPath, item in

      guard let self else { return }
      configure(cell: cell, indexPath: indexPath, item: item)
    }

    self.dataSource = UICollectionViewDiffableDataSource<Section, Item>(
      collectionView: self.collectionView
    ) { collectionView, indexPath, item in
      collectionView.dequeueConfiguredReusableCell(
        using: cellRegistration,
        for: indexPath,
        item: item
      )
    }

    observe { [weak self] in
      guard let self else { return }
      dataSource.apply(
        NSDiffableDataSourceSnapshot(model: model),
        animatingDifferences: true
      )
    }

    present(item: $model.destination.connect) { model in
      UINavigationController(
        rootViewController: ConnectToNetworkViewController(model: model)
      )
    }

    navigationDestination(item: $model.destination.detail) { model in
      NetworkDetailViewController(model: model)
    }
  }

  private func configure(
    cell: UICollectionViewListCell,
    indexPath: IndexPath,
    item: Item
  ) {
    var configuration = cell.defaultContentConfiguration()
    defer { cell.contentConfiguration = configuration }
    cell.accessories = []

    switch item {
    case .isOn:
      configuration.text = "Wi-Fi"
      cell.accessories = [
        .customView(
          configuration: UICellAccessory.CustomViewConfiguration(
            customView: UISwitch(isOn: $model.isOn),
            placement: .trailing(displayed: .always)
          )
        )
      ]

    case let .selectedNetwork(networkID):
      guard let network = model.foundNetworks.first(where: { $0.id == networkID })
      else { return }
      configureNetwork(cell: cell, network: network, indexPath: indexPath, item: item)

    case let .foundNetwork(network):
      configureNetwork(cell: cell, network: network, indexPath: indexPath, item: item)
    }

    func configureNetwork(
      cell: UICollectionViewListCell,
      network: Network,
      indexPath: IndexPath,
      item: Item
    ) {
      configuration.text = network.name
      cell.accessories.append(
        .detail(displayed: .always) { [weak self] in
          guard let self else { return }
          model.infoButtonTapped(network: network)
        }
      )
      if network.isSecured {
        let image = UIImage(systemName: "lock.fill")!
        let imageView = UIImageView(image: image)
        imageView.tintColor = .darkText
        cell.accessories.append(
          .customView(
            configuration: UICellAccessory.CustomViewConfiguration(
              customView: imageView,
              placement: .trailing(displayed: .always)
            )
          )
        )
      }
      let image = UIImage(systemName: "wifi", variableValue: network.connectivity)!
      let imageView = UIImageView(image: image)
      imageView.tintColor = .darkText
      cell.accessories.append(
        .customView(
          configuration: UICellAccessory.CustomViewConfiguration(
            customView: imageView,
            placement: .trailing(displayed: .always)
          )
        )
      )
      if network.id == model.selectedNetworkID {
        cell.accessories.append(
          .customView(
            configuration: UICellAccessory.CustomViewConfiguration(
              customView: UIImageView(image: UIImage(systemName: "checkmark")!),
              placement: .leading(displayed: .always),
              reservedLayoutWidth: .custom(1)
            )
          )
        )
      }
    }
  }

  override func collectionView(
    _ collectionView: UICollectionView,
    shouldSelectItemAt indexPath: IndexPath
  ) -> Bool {
    indexPath.section != 0 || indexPath.row != 0
  }

  override func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    guard let network = dataSource.itemIdentifier(for: indexPath)?.foundNetwork
    else { return }
    model.networkTapped(network)
  }

  enum Section: Hashable, Sendable {
    case top
    case foundNetworks
  }

  @CasePathable
  @dynamicMemberLookup
  enum Item: Hashable, Sendable {
    case isOn
    case selectedNetwork(Network.ID)
    case foundNetwork(Network)
  }
}

extension NSDiffableDataSourceSnapshot<
  WiFiSettingsViewController.Section,
  WiFiSettingsViewController.Item
> {
  @MainActor
  init(model: WiFiSettingsModel) {
    self.init()

    appendSections([.top])
    appendItems([.isOn], toSection: .top)

    guard model.isOn
    else { return }

    if let selectedNetworkID = model.selectedNetworkID {
      appendItems([.selectedNetwork(selectedNetworkID)], toSection: .top)
    }

    appendSections([.foundNetworks])
    appendItems(
      model.foundNetworks
        .sorted { lhs, rhs in
          (lhs.isSecured ? 1 : 0, lhs.connectivity)
            > (rhs.isSecured ? 1 : 0, rhs.connectivity)
        }
        .compactMap { network in
          network.id == model.selectedNetworkID
            ? nil
            : .foundNetwork(network)
        },
      toSection: .foundNetworks
    )
  }
}

#Preview {
  let model = WiFiSettingsModel(foundNetworks: .mocks)
  return UIViewControllerRepresenting {
    UINavigationController(
      rootViewController: WiFiSettingsViewController(model: model)
    )
  }
  .task {
    while true {
      try? await Task.sleep(for: .seconds(1))
      guard Bool.random() else { continue }
      if Bool.random() {
        guard let randomIndex = (0..<model.foundNetworks.count).randomElement()
        else { continue }
        if model.foundNetworks[randomIndex].id != model.selectedNetworkID {
          model.foundNetworks.remove(at: randomIndex)
        }
      } else {
        model.foundNetworks.append(
          Network(
            name: goofyWiFiNames.randomElement()!,
            isSecured: !(1...1_000).randomElement()!.isMultiple(of: 5),
            connectivity: Double((1...100).randomElement()!) / 100
          )
        )
      }
    }
  }
}
