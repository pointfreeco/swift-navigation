import SwiftUI
import SwiftUINavigation

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct OptionalConfirmationDialogs: View {
  @State private var model = FeatureModel()

  var body: some View {
    List {
      Stepper("Number: \(self.model.count)", value: self.$model.count)
      Button {
        Task { await self.model.numberFactButtonTapped() }
      } label: {
        HStack {
          Text("Get number fact")
          if self.model.isLoading {
            Spacer()
            ProgressView()
          }
        }
      }
      .disabled(self.model.isLoading)
      .confirmationDialog(
        title: { Text("Fact about \($0.number)") },
        titleVisibility: .visible,
        unwrapping: self.$model.fact,
        actions: {
          Button("Get another fact about \($0.number)") {
            Task { await self.model.numberFactButtonTapped() }
          }
        },
        message: { Text($0.description) }
      )
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
    self.isLoading = true
    self.fact = await getNumberFact(self.count)
    self.isLoading = false
  }
}

#Preview {
  OptionalConfirmationDialogs()
}
