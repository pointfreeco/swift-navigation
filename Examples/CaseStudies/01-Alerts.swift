import SwiftUINavigation

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct OptionalAlerts: View {
  @ObservedObject private var viewModel = ViewModel()

  var body: some View {
    List {
      Stepper("Number: \(self.viewModel.count)", value: self.$viewModel.count)
      Button(action: { self.viewModel.numberFactButtonTapped() }) {
        HStack {
          Text("Get number fact")
          if self.viewModel.isLoading {
            Spacer()
            ProgressView()
          }
        }
      }
      .disabled(self.viewModel.isLoading)
    }
    .alert(
      title: { Text("Fact about \($0.number)") },
      unwrapping: self.$viewModel.fact,
      actions: {
        Button("Get another fact about \($0.number)") {
          self.viewModel.numberFactButtonTapped()
        }
        Button("Cancel", role: .cancel) {
          self.viewModel.fact = nil
        }
      },
      message: { Text($0.description) }
    )
    .navigationTitle("Alerts")
  }
}

private class ViewModel: ObservableObject {
  @Published var count = 0
  @Published var isLoading = false
  @Published var fact: Fact?

  func numberFactButtonTapped() {
    self.isLoading = true
    Task { @MainActor in
      self.fact = await getNumberFact(self.count)
      self.isLoading = false
    }
  }
}
