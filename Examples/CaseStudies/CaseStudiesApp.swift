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
      if #available(iOS 16, *) {
        self.window?.rootViewController = UIHostingController(
          rootView: NavigationStack {
            NestedDestinationView(model: model)
          }
          .navigationViewStyle(.stack)
        )
      } else {
        self.window?.rootViewController = UIHostingController(
          rootView: NavigationView {
            NestedLinkView(model: model)
          }
          .navigationViewStyle(.stack)
        )
      }
    } else {
      self.window?.rootViewController = UIHostingController(rootView: RootView())
    }
//    self.window?.rootViewController = UIHostingController(
//      rootView: NavigationStack {
//        AView(
//          model: AModel(
////            b: BModel(
////              c: CModel(
////                d: DModel(
////                  e: EModel()
////                )
////              )
////            )
//          )
//        )
//      }
//    )
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
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Text("\(self.model.secondsElapsed)")

      Button("Environment dismissal") {
        self.dismiss()
      }

      Button {
        self.model.child = .init()
      } label: {
        Text("Button to child feature")
      }

      Button {
        self.model.child = .init(child: .init(child: .init()))
      } label: {
        Text("Button to three layers deep")
      }
    }
    .navigationBarTitle(Text("\(self.model.secondsElapsed)"))
    .navigationDestination(unwrapping: self.$model.child) { $child in
      VStack {
        Button("State dismissal") {
          self.model.child = nil
        }
        NestedDestinationView(model: child)
      }
    }
  }
}

@available(iOS 14, *)
struct NestedLinkView: View {
  @ObservedObject var model: NestedModel
  @Environment(\.presentationMode) @Binding var presentationMode

  var body: some View {
    VStack {
      Text("\(self.model.secondsElapsed)")
      NavigationLink(
        unwrapping: self.$model.child
      ) { isActive in
        self.model.child = isActive ? NestedModel() : nil
      } destination: { $child in
        VStack {
          Button("State dismissal") {
            self.model.child = nil
          }
          NestedLinkView(model: child)
        }
      } label: {
        Text("Link to child feature")
      }

      Button("Environment dismissal") {
        self.presentationMode.dismiss()
      }

      Button {
        self.model.child = .init()
      } label: {
        Text("Button to child feature")
      }

      Button {
        self.model.child = .init(child: .init(child: .init()))
      } label: {
        Text("Button to three layers deep")
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
//    Timer.publish(every: 1, on: .main, in: .default)
//      .autoconnect()
//      .assign(to: &self.$date)
  }

  static func == (lhs: NestedModel, rhs: NestedModel) -> Bool {
    lhs === rhs
  }
}

// MARK: -

@available(iOS 14, *)
final class AModel: ObservableObject, Equatable {
  @Published var b: BModel?

  init(b: BModel? = nil) {
    self.b = b
  }

  static func == (lhs: AModel, rhs: AModel) -> Bool { lhs === rhs }
}

@available(iOS 14, *)
final class BModel: ObservableObject, Equatable {
  @Published var c: CModel?

  init(c: CModel? = nil) {
    self.c = c
  }

  static func == (lhs: BModel, rhs: BModel) -> Bool { lhs === rhs }
}

@available(iOS 14, *)
final class CModel: ObservableObject, Equatable {
  @Published var d: DModel?

  init(d: DModel? = nil) {
    self.d = d
  }

  static func == (lhs: CModel, rhs: CModel) -> Bool { lhs === rhs }
}

@available(iOS 14, *)
final class DModel: ObservableObject, Equatable {
  @Published var e: EModel?

  init(e: EModel? = nil) {
    self.e = e
  }

  static func == (lhs: DModel, rhs: DModel) -> Bool { lhs === rhs }
}

@available(iOS 14, *)
final class EModel: ObservableObject, Equatable {
//  @Published var e: EModel?
//
//  init(e: EModel? = nil) {
//    self.e = e
//  }

  static func == (lhs: EModel, rhs: EModel) -> Bool { lhs === rhs }
}

@available(iOS 16, *)
struct AView: View {
  @ObservedObject var model: AModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Button {
        self.model.b = .init()
      } label: {
        Text("Button to B")
      }

      Button {
        self.model.b = .init(c: .init(d: .init()))
      } label: {
        Text("Button to B-C-D")
      }
    }
    .navigationBarTitle(Text("A"))
    .navigationDestination(unwrapping: self.$model.b) { $b in
      VStack {
        Button("State dismissal") {
          self.model.b = nil
        }
        BView(model: b)
      }
    }
  }
}

@available(iOS 16, *)
struct BView: View {
  @ObservedObject var model: BModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Button("Environment dismissal") {
        self.dismiss()
      }

      Button {
        self.model.c = .init()
      } label: {
        Text("Button to C")
      }

      Button {
        self.model.c = .init(d: .init(e: .init()))
      } label: {
        Text("Button to C-D-E")
      }
    }
    .navigationBarTitle(Text("B"))
    .navigationDestination(unwrapping: self.$model.c) { $c in
      VStack {
        Button("State dismissal") {
          self.model.c = nil
        }
        CView(model: c)
      }
    }
  }
}

@available(iOS 16, *)
struct CView: View {
  @ObservedObject var model: CModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Button("Environment dismissal") {
        self.dismiss()
      }

      Button {
        self.model.d = .init()
      } label: {
        Text("Button to D")
      }

      Button {
        self.model.d = .init(e: .init())
      } label: {
        Text("Button to D-E")
      }
    }
    .navigationBarTitle(Text("C"))
    .navigationDestination(unwrapping: self.$model.d) { $d in
      VStack {
        Button("State dismissal") {
          self.model.d = nil
        }
        DView(model: d)
      }
    }
  }
}

@available(iOS 16, *)
struct DView: View {
  @ObservedObject var model: DModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Button("Environment dismissal") {
        self.dismiss()
      }

      Button {
        self.model.e = .init()
      } label: {
        Text("Button to E")
      }

//      Button {
//        self.model.d = .init()
//      } label: {
//        Text("Button to E-")
//      }
    }
    .navigationBarTitle(Text("D"))
    .navigationDestination(unwrapping: self.$model.e) { $e in
      VStack {
        Button("State dismissal") {
          self.model.e = nil
        }
        EView(model: e)
      }
    }
  }
}

@available(iOS 16, *)
struct EView: View {
  @ObservedObject var model: EModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Button("Environment dismissal") {
        self.dismiss()
      }

//      Button {
//        self.model.e = .init()
//      } label: {
//        Text("Button to F")
//      }
//
//      Button {
//        self.model.d = .init()
//      } label: {
//        Text("Button to F-")
//      }
    }
    .navigationBarTitle(Text("E"))
//    .navigationDestination(unwrapping: self.$model.e) { $e in
//      VStack {
//        Button("State dismissal") {
//          self.model.e = nil
//        }
//        EView(model: e)
//      }
//    }
  }
}


