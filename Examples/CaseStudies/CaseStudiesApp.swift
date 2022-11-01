import SwiftUINavigation
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    self.window = (scene as? UIWindowScene).map(UIWindow.init(windowScene:))
    if #available(iOS 14, *) {
      let model = NestedModel(
        child: .init(
          child: .init(
            child: .init(
              child: .init(
                child: .init(
                  child: .init()
                )
              )
            )
          )
        )
      )
//      if #available(iOS 16, *) {
//        self.window?.rootViewController = UIHostingController(
//          rootView: NavigationStack {
//            NestedDestinationView(model: model)
//          }
//          .navigationViewStyle(.stack)
//        )
//      } else {
        self.window?.rootViewController = UIHostingController(
          rootView: NavigationView {
            NestedLinkView(model: model)
          }
          .navigationViewStyle(.stack)
        )
//      }
    } else {
      self.window?.rootViewController = UIHostingController(rootView: RootView())
    }
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

@available(iOS 16, *)
struct NestedDestinationView: View {
  @ObservedObject var model: NestedModel

  var body: some View {
    VStack {
      Text("\(self.model.secondsElapsed)")

      Button {
        self.model.child = .init()
      } label: {
        Text("Button to child feature")
      }
    }
    .navigationBarTitle(Text("\(self.model.secondsElapsed)"))
    .navigationDestination(unwrapping: self.$model.child) { $child in
      Button("Dismiss") {
        self.model.child = nil
      }
      NestedDestinationView(model: child)
    }
  }
}

@available(iOS 14, *)
struct NestedLinkView: View {
  @ObservedObject var model: NestedModel

  var body: some View {
    VStack {
      Text("\(self.model.secondsElapsed)")
      NavigationLink(
        unwrapping: self.$model.child
      ) { isActive in
        self.model.child = isActive ? NestedModel() : nil
      } destination: { $child in
        Button("Dismiss") {
          self.model.child = nil
        }
        NestedLinkView(model: child)
      } label: {
        Text("Link to child feature")
      }

      Button {
        self.model.child = .init()
      } label: {
        Text("Button to child feature")
      }
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
