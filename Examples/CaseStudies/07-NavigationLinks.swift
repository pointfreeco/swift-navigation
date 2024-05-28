import SwiftUI
import SwiftUINavigation

struct OptionalNavigationLinks: View {
  @State private var model = FeatureModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(model.count)", value: $model.count)

        HStack {
          Button("Get number fact") {
            Task { await model.setFactNavigation(isActive: true) }
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
        ForEach(model.savedFacts) { fact in
          Text(fact.description)
        }
        .onDelete { model.removeSavedFacts(atOffsets: $0) }
      } header: {
        Text("Saved Facts")
      }
    }
    .navigationDestination(item: $model.fact) { $fact in
      FactEditor(fact: $fact.description)
        .disabled(model.isLoading)
        .foregroundColor(model.isLoading ? .gray : nil)
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              Task { await model.cancelButtonTapped() }
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
              Task { await model.saveButtonTapped(fact: fact) }
            }
          }
        }
    }
    .navigationTitle("Links")
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
  func setFactNavigation(isActive: Bool) async {
    if isActive {
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
    } else {
      task?.cancel()
      task = nil
      fact = nil
    }
  }

  @MainActor
  func cancelButtonTapped() async {
    await setFactNavigation(isActive: false)
  }

  @MainActor
  func saveButtonTapped(fact: Fact) async {
    savedFacts.append(fact)
    await setFactNavigation(isActive: false)
  }

  @MainActor
  func removeSavedFacts(atOffsets offsets: IndexSet) {
    savedFacts.remove(atOffsets: offsets)
  }
}

#Preview {
  NavigationStack {
    OptionalNavigationLinks()
  }
}
