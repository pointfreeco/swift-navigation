import SwiftUI
import SwiftUINavigation

@available(iOS 16, *)
struct NavigationDestinations: View {
  @State private var model = FeatureModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(self.model.count)", value: self.$model.count)

        HStack {
          Button("Get number fact") {
            Task { await self.model.numberFactButtonTapped() }
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
    .navigationTitle("Destinations")
    .navigationDestination(unwrapping: self.$model.fact) { $fact in
      FactEditor(fact: $fact.description)
        .disabled(self.model.isLoading)
        .foregroundColor(self.model.isLoading ? .gray : nil)
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              Task { await self.model.cancelButtonTapped() }
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
              Task { await self.model.saveButtonTapped(fact: fact) }
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
        TextEditor(text: self.$fact)
      } else {
        TextField("Untitled", text: self.$fact)
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
    self.task?.cancel()
  }

  @MainActor
  func setFactNavigation(isActive: Bool) async {
    if isActive {
      self.isLoading = true
      self.fact = Fact(description: "\(self.count) is still loading...", number: self.count)
      self.task = Task {
        let fact = await getNumberFact(self.count)
        self.isLoading = false
        guard !Task.isCancelled
        else { return }
        self.fact = fact
      }
      await self.task?.value
    } else {
      self.task?.cancel()
      self.task = nil
      self.fact = nil
    }
  }

  @MainActor
  func numberFactButtonTapped() async {
    await self.setFactNavigation(isActive: true)
  }

  @MainActor
  func cancelButtonTapped() async {
    await self.setFactNavigation(isActive: false)
  }

  @MainActor
  func saveButtonTapped(fact: Fact) async {
    self.savedFacts.append(fact)
    await self.setFactNavigation(isActive: false)
  }

  @MainActor
  func removeSavedFacts(atOffsets offsets: IndexSet) {
    self.savedFacts.remove(atOffsets: offsets)
  }
}

#Preview {
  NavigationStack {
    NavigationDestinations()
  }
}
