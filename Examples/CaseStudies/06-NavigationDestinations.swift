import SwiftUI
import SwiftUINavigation

@available(iOS 16, *)
struct NavigationDestinations: View {
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
    .navigationTitle("Destinations")
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
  }
}

private struct FactEditor: View {
  @Binding var fact: String

  var body: some View {
    VStack {
      if #available(iOS 14, *) {
        TextEditor(text: $fact)
      } else {
        TextField("Untitled", text: $fact)
      }
    }
    .padding()
    .navigationBarTitle("Fact Editor")
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
  func numberFactButtonTapped() async {
    await setFactNavigation(isActive: true)
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
    NavigationDestinations()
  }
}
