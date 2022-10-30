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
    }
    .navigationTitle(Text("\(self.model.secondsElapsed)"))
  }
}

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
