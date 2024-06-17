import SwiftUI
import SwiftUINavigation

struct AlertsWithAlertState: SwiftUICaseStudy {
  let caseStudyTitle = "Alert/dialog state"
  let readMe = """
    The 'AlertState' type is a purely data description of all the properties of an alert, such \
    as its title, message and even actions. You can use 'AlertState' to make your alerts more \
    testable, which can be useful when alerts involve complex and nuanced logic. This also helps \
    keep logic in your observable model and out of your views.
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
    .alert($model.alert)
  }
}

@Observable
private class FeatureModel {
  var count = 0
  var isLoading = false
  var alert: AlertState<Never>?

  @MainActor
  func numberFactButtonTapped() async {
    isLoading = true
    defer { isLoading = false }
    let fact = await getNumberFact(count)
    alert = AlertState {
      TextState("Fact about \(count)")
    } actions: {
      ButtonState {
        TextState("OK")
      }
    } message: {
      TextState(fact.description)
    }
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      AlertsWithAlertState()
    }
  }
}
