import SwiftUI
import SwiftUINavigation

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct OptionalAlerts: View {
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
    }
    .alert(
      title: { Text("Fact about \($0.number)") },
      unwrapping: self.$model.fact,
      actions: {
        Button("Get another fact about \($0.number)") {
          Task { await self.model.numberFactButtonTapped() }
        }
        Button("Close", role: .cancel) {
          self.model.fact = nil
        }
      },
      message: { Text($0.description) }
    )
    .navigationTitle("Alerts")
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
  OptionalAlerts()
}
