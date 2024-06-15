import SwiftUI
import SwiftUINavigation

struct Alerts: CaseStudy {
  let title = "Alerts"
  let readMe = """
    The 'alert' modifier in SwiftUI can lead one to model their domain imprecisely as it \
    takes both a binding of a boolean to control whether or not the alert is shown, and \
    a piece of optional state that represents what is being alerted.

    This library comes with a new 'alert' view modifier that allows one to drive an alert off \
    of a single piece of optional state.
    """
  @State private var model = FeatureModel()

  var body: some View {
    Section {
      Stepper("Number: \(model.count)", value: $model.count)
      Button {
        Task { await model.numberFactButtonTapped() }
      } label: {
        LabeledContent("Get number fact") {
          if model.isLoading {
            ProgressView()
          }
        }
      }
    }
    .disabled(model.isLoading)
    .alert(item: $model.fact) {
      Text("Fact about \($0.number)")
    } actions: {
      Button("Get another fact about \($0.number)") {
        Task { await model.numberFactButtonTapped() }
      }
      Button("Close", role: .cancel) {
        model.fact = nil
      }
    } message: {
      Text($0.description)
    }
  }
}

@Observable
private class FeatureModel {
  var count = 0
  var isLoading = false
  var fact: Fact?

  @MainActor
  func numberFactButtonTapped() async {
    isLoading = true
    defer { isLoading = false }
    fact = await getNumberFact(count)
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      Alerts()
    }
  }
}
