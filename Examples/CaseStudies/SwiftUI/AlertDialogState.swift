import SwiftUI
import SwiftUINavigation

struct AlertDialogState: SwiftUICaseStudy {
  let caseStudyTitle = "Alert/dialog state"
  let readMe = """
    This case study shows how to drive alerts and dialog using the `AlertState` and \
    `ConfirmationDialogState` data types. These data types are pure data descriptions of all the \
    properties of an alert or dialog, such as its title, message, and even actions. You can these \
    types to make your alerts more testable, which can be useful when alerts involve complex and \
    nuanced logic. This also helps keep logic in your observable model and out of your views.
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
    .alert($model.alert) { action in
      await model.alertButtonTapped(action)
    }
  }
}

@MainActor
@Observable
private class FeatureModel {
  var count = 0
  var isLoading = false
  var alert: AlertState<AlertAction>?

  enum AlertAction {
    case getFact
  }

  func numberFactButtonTapped() async {
    await getFact()
  }

  func alertButtonTapped(_ action: AlertAction?) async {
    switch action {
    case .getFact:
      await getFact()
    case nil:
      break
    }
  }

  private func getFact() async {
    isLoading = true
    defer { isLoading = false }
    let fact = await getNumberFact(count)
    alert = AlertState {
      TextState("Fact about \(count)")
    } actions: {
      ButtonState(role: .cancel) {
        TextState("OK")
      }
      ButtonState(action: .getFact) {
        TextState("Get another fact")
      }
    } message: {
      TextState(fact.description)
    }
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      AlertDialogState()
    }
  }
}
