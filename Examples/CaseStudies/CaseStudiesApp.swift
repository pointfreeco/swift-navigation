import SwiftUINavigation

import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    self.window = (scene as? UIWindowScene).map(UIWindow.init(windowScene:))
    self.window?.rootViewController = UIHostingController(rootView: RootView())
    self.window?.makeKeyAndVisible()
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    true
  }
}

@available(iOS 14, *)
struct NestedView: View {
  @ObservedObject var model: NestedModel

  var body: some View {
    VStack {
      Text("\(self.model.secondsElapsed)")
      NavigationLink(
        unwrapping: self.$model.child
      ) { isActive in
        self.model.child = isActive ? NestedModel() : nil
      } destination: { $child in
        NestedView(model: child)
      } label: {
        Text("Go to child feature")
      }

      // TODO: document that shouldn't import both SwiftUI and SwiftUINavigation
    }
    .navigationBarTitle(Text("\(self.model.secondsElapsed)"))
  }
}

@available(iOS 14, *)
final class NestedModel: ObservableObject, Equatable {
  @Published var child: NestedModel?
  @Published var date = Date()
  @Published var start = Date()

  var secondsElapsed: Int {
    Int(self.date.timeIntervalSince1970 - self.start.timeIntervalSince1970)
  }

  init(child: NestedModel? = nil) {
    self.child = child
    Timer.publish(every: 1, on: .main, in: .default)
      .autoconnect()
      .assign(to: &self.$date)
  }

  static func == (lhs: NestedModel, rhs: NestedModel) -> Bool {
    lhs === rhs
  }
}
