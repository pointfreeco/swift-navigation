import SwiftUI
import SwiftUINavigation

struct OptionalSheets: View {
  @ObservedObject private var model = FeatureModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(self.model.count)", value: self.$model.count)

        HStack {
          Button("Get number fact") {
            self.model.numberFactButtonTapped()
          }

          if self.model.isLoading {
            Spacer()
            ProgressView()
          }
        }
      } header: {
        Text("Fact Finder")
      }

      Section {
        ForEach(self.model.savedFacts) { fact in
          Text(fact.description)
        }
        .onDelete { self.model.removeSavedFacts(atOffsets: $0) }
      } header: {
        Text("Saved Facts")
      }
    }
    .sheet(unwrapping: self.$model.fact) { $fact in
      NavigationView {
        FactEditor(fact: $fact.description)
          .disabled(self.model.isLoading)
          .foregroundColor(self.model.isLoading ? .gray : nil)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                self.model.cancelButtonTapped()
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Save") {
                self.model.saveButtonTapped(fact: fact)
              }
            }
          }
      }
    }
    .navigationTitle("Sheets")
  }
}

private struct FactEditor: View {
  @Binding var fact: String

  var body: some View {
    VStack {
      TextEditor(text: self.$fact)
    }
    .padding()
    .navigationTitle("Fact editor")
  }
}

private class FeatureModel: ObservableObject {
  @Published var count = 0
  @Published var fact: Fact?
  @Published var isLoading = false
  @Published var savedFacts: [Fact] = []
  private var task: Task<Void, Error>?

  deinit {
    self.task?.cancel()
  }

  func numberFactButtonTapped() {
    self.isLoading = true
    self.fact = Fact(description: "\(self.count) is still loading...", number: self.count)
    self.task = Task { @MainActor in
      let fact = await getNumberFact(self.count)
      self.isLoading = false
      try Task.checkCancellation()
      self.fact = fact
    }
  }

  func cancelButtonTapped() {
    self.task?.cancel()
    self.task = nil
    self.fact = nil
  }

  func saveButtonTapped(fact: Fact) {
    self.task?.cancel()
    self.task = nil
    self.savedFacts.append(fact)
    self.fact = nil
  }

  func removeSavedFacts(atOffsets offsets: IndexSet) {
    self.savedFacts.remove(atOffsets: offsets)
  }
}
