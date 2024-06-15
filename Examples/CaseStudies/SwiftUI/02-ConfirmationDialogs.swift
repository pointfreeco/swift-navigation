import SwiftUI
import SwiftUINavigation

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct OptionalConfirmationDialogs: View {
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
  OptionalConfirmationDialogs()
}
