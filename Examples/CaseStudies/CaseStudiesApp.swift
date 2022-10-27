import SwiftUINavigation

@main
struct CaseStudiesApp: App {
  var body: some Scene {
    WindowGroup {
//      RootView()

      NavigationView {
        NestedView(
          model: NestedModel(
            child: NestedModel(
              child: NestedModel(
                child: NestedModel(
                  child: NestedModel(child: .init(child: .init(child: .init())))
                )
              )
            )
          )
        )
      }
      .navigationViewStyle(.stack)


    }
  }
}

struct NestedView: View {
  @ObservedObject var model: NestedModel

  var body: some View {
    NavLink(
      unwrapping: self.$model.child
    ) { isActive in
      self.model.child = isActive ? NestedModel() : nil
    } destination: { $child in
      NestedView(model: child)
    } label: {
      Text("Go to child feature")
    }
  }
}

class NestedModel: ObservableObject, Equatable {
  @Published var child: NestedModel?
  init(child: NestedModel? = nil) {
    self.child = child
  }

  static func == (lhs: NestedModel, rhs: NestedModel) -> Bool {
    lhs === rhs
  }
}
