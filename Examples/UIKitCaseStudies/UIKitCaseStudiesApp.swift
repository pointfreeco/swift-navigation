import SwiftUI
import UIKitNavigation

@main
@MainActor
struct UIKitCaseStudiesApp: App {
  static let navigationController = {
    // @UIBindable var model = AppModel()
    // model.path.append(AppModel.Path.counter(CounterModel()))
    // model.path.append(AppModel.Path.form(FormModel()))
    //
    // let navigationController = UINavigationController(path: $model.path) {
    //   NavigationRootViewController()
    // }
    // // let navigationController = UINavigationController(
    // //   rootViewController: NavigationRootViewController()
    // // )
    // navigationController.navigationDestination(for: AppModel.Path.self) { route in
    //   switch route {
    //   case let .collection(model):
    //     CollectionViewController(model: model)
    //   case let .counter(model):
    //     CounterViewController(model: model)
    //   case let .form(model):
    //     FormViewController(model: model)
    //   }
    // }

    UINavigationController(
      rootViewController: WiFiSettingsViewController(
        model: WiFiSettingsModel(
          foundNetworks: .mocks
        )
      )
    )
  }()

  var body: some Scene {
    WindowGroup {
      if NSClassFromString("XCTestCase") == nil {
        WithPerceptionTracking {
          UIViewControllerRepresenting {
            //        AppViewController()
            Self.navigationController
          }
        }
      }
    }
  }
}
