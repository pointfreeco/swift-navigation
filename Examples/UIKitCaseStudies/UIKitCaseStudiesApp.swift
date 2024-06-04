import SwiftUI
import UIKitNavigation
import XCTestDynamicOverlay

// TODO: Clean up case studies

@main
@MainActor
struct UIKitCaseStudiesApp: App {
  @UIBindable var model: AppModel
  let navigationController: UINavigationController

  init() {
    guard !_XCTIsTesting else {
      self.model = AppModel()
      self.navigationController = UINavigationController()
      return
    }
    // let path = try! UINavigationPath(
    //   JSONDecoder().decode(
    //     UINavigationPath.CodableRepresentation.self,
    //     from: Data(#"["Si", "42"]"#.utf8)
    //   )
    // )
    @UIBindable var model = AppModel(/*path: path*/)
    model.path.append(AppModel.Path.counter(CounterModel()))
    model.path.append(AppModel.Path.form(FormModel()))

    // model.path.append(1)
    // model.path.append("Blob")

    let navigationController = NavigationStackController(path: $model.path) {
      NavigationRootViewController()
    }
    // let navigationController = UINavigationController(
    //   rootViewController: NavigationRootViewController()
    // )
    navigationController.navigationDestination(for: Int.self) { n in
      MainActor.assumeIsolated {
        let vc = UIViewController()
        vc.navigationItem.title = "\(n)"
        return vc
      }
    }
    navigationController.navigationDestination(for: String.self) { n in
      MainActor.assumeIsolated {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.navigationItem.title = n
        return vc
      }
    }
    navigationController.navigationDestination(for: AppModel.Path.self) { route in
      switch route {
      case let .collection(model):
        CollectionViewController(model: model)
      case let .counter(model):
        CounterViewController(model: model)
      case let .form(model):
        FormViewController(model: model)
      }
    }
    // let navigationController = UINavigationController(
    //   rootViewController: WiFiSettingsViewController(
    //     model: WiFiSettingsModel(
    //       foundNetworks: .mocks
    //     )
    //   )
    // )
    self.model = model
    self.navigationController = navigationController
  }

  var body: some Scene {
    WindowGroup {
      if NSClassFromString("XCTestCase") == nil {
        WithPerceptionTracking {
          UIViewControllerRepresenting {
            // AppViewController()
            self.navigationController
          }
        }
      }
    }
  }
}
