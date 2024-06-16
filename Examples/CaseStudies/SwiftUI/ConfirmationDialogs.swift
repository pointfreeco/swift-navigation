import SwiftUI
import SwiftUINavigation

struct ConfirmationDialogs: SwiftUICaseStudy {
  let caseStudyTitle = "Confirmation dialogs"
  let readMe = """
    The 'confirmationDialog' modifier in SwiftUI can lead one to model their domain imprecisely as \
    it takes both a binding of a boolean to control whether or not the dialog is shown, and \
    a piece of optional state that represents what is being presented.

    This library comes with a new 'confirmationDialog' view modifier that allows one to drive an \
    dialog off of a single piece of optional state.
    """
  @State private var model = FeatureModel()

  var body: some View {
    List {
      Stepper("Number: \(model.count)", value: $model.count)
      Button {
        Task { await model.numberFactButtonTapped() }
      } label: {
        HStack {
          Text("Get number fact")
          if model.isLoading {
            Spacer()
            ProgressView()
          }
        }
      }
      .disabled(model.isLoading)
      .confirmationDialog(item: $model.fact, titleVisibility: .visible) {
        Text("Fact about \($0.number)")
      } actions: {
        Button("Get another fact about \($0.number)") {
          Task { await model.numberFactButtonTapped() }
        }
      } message: {
        Text($0.description)
      }
    }
    .navigationTitle("Dialogs")
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
      ConfirmationDialogs()
    }
  }
}
