import SwiftUI
import SwiftUINavigation

struct OptionalSheets: View {
  @State private var model = FeatureModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(model.count)", value: $model.count)

        HStack {
          Button("Get number fact") {
            Task { await model.numberFactButtonTapped() }
          }

          if model.isLoading {
            Spacer()
            ProgressView()
          }
        }
      } header: {
        Text("Fact Finder")
      }

      Section {
        ForEach(model.savedFacts) { fact in
          Text(fact.description)
        }
        .onDelete { model.removeSavedFacts(atOffsets: $0) }
      } header: {
        Text("Saved Facts")
      }
    }
    .sheet(item: $model.fact) { $fact in
      NavigationStack {
        FactEditor(fact: $fact.description)
          .disabled(model.isLoading)
          .foregroundColor(model.isLoading ? .gray : nil)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                model.cancelButtonTapped()
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Save") {
                model.saveButtonTapped(fact: fact)
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
      TextEditor(text: $fact)
    }
    .padding()
    .navigationTitle("Fact editor")
  }
}

@Observable
private class FeatureModel {
  var count = 0
  var fact: Fact?
  var isLoading = false
  var savedFacts: [Fact] = []
  private var task: Task<Void, Never>?

  deinit {
    task?.cancel()
  }

  @MainActor
  func numberFactButtonTapped() async {
    isLoading = true
    fact = Fact(description: "\(count) is still loading...", number: count)
    task = Task {
      let fact = await getNumberFact(self.count)
      isLoading = false
      guard !Task.isCancelled
      else { return }
      self.fact = fact
    }
    await task?.value
  }

  @MainActor
  func cancelButtonTapped() {
    task?.cancel()
    task = nil
    fact = nil
  }

  @MainActor
  func saveButtonTapped(fact: Fact) {
    task?.cancel()
    task = nil
    savedFacts.append(fact)
    self.fact = nil
  }

  @MainActor
  func removeSavedFacts(atOffsets offsets: IndexSet) {
    savedFacts.remove(atOffsets: offsets)
  }
}

#Preview {
  OptionalSheets()
}
