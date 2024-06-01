import SwiftUI
import UIKitNavigation

@main
@MainActor
struct UIKitCaseStudiesApp: App {
  static let navigationController = {
//    let path = try! UINavigationPath(
//      JSONDecoder().decode(
//        UINavigationPath.CodableRepresentation.self,
//        from: Data(#"["Si", "42"]"#.utf8)
//      )
//    )
    @UIBindable var model = AppModel(/*path: path*/)
    // model.path.append(AppModel.Path.counter(CounterModel()))
    // model.path.append(AppModel.Path.form(FormModel()))

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
    return navigationController
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
