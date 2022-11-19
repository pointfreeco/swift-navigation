import SwiftUI
import SwiftUINavigation

struct OptionalNavigationLinks: View {
  @ObservedObject private var model = FeatureModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(self.model.count)", value: self.$model.count)

        HStack {
          NavigationLink(unwrapping: self.$model.fact) {
            self.model.setFactNavigation(isActive: $0)
          } destination: { $fact in
            FactEditor(fact: $fact.description)
              .disabled(self.model.isLoading)
              .foregroundColor(self.model.isLoading ? .gray : nil)
              .navigationBarBackButtonHidden(true)
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
          } label: {
            Text("Get number fact")
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
    .navigationTitle("Links")
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

  func setFactNavigation(isActive: Bool) {
    if isActive {
      self.isLoading = true
      self.fact = Fact(description: "\(self.count) is still loading...", number: self.count)
      self.task = Task { @MainActor in
        let fact = await getNumberFact(self.count)
        self.isLoading = false
        try Task.checkCancellation()
        self.fact = fact
      }
    } else {
      self.task?.cancel()
      self.task = nil
      self.fact = nil
    }
  }

  func cancelButtonTapped() {
    self.setFactNavigation(isActive: false)
  }

  func saveButtonTapped(fact: Fact) {
    self.savedFacts.append(fact)
    self.setFactNavigation(isActive: false)
  }

  func removeSavedFacts(atOffsets offsets: IndexSet) {
    self.savedFacts.remove(atOffsets: offsets)
  }
}
