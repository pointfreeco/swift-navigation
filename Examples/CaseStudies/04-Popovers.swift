import SwiftUI
import SwiftUINavigation

struct OptionalPopovers: View {
  @State private var model = FeatureModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(self.model.count)", value: self.$model.count)

        HStack {
          Button("Get number fact") {
            Task { await self.model.numberFactButtonTapped() }
          }
          .popover(unwrapping: self.$model.fact, arrowEdge: .bottom) { $fact in
            NavigationView {
              FactEditor(fact: $fact.description)
                .disabled(self.model.isLoading)
                .foregroundColor(self.model.isLoading ? .gray : nil)
                .navigationBarItems(
                  leading: Button("Cancel") {
                    self.model.cancelButtonTapped()
                  },
                  trailing: Button("Save") {
                    self.model.saveButtonTapped(fact: fact)
                  }
                )
            }
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
    .navigationTitle("Popovers")
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
  func numberFactButtonTapped() async {
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
  }

  @MainActor
  func cancelButtonTapped() {
    self.task?.cancel()
    self.task = nil
    self.fact = nil
  }

  @MainActor
  func saveButtonTapped(fact: Fact) {
    self.task?.cancel()
    self.task = nil
    self.savedFacts.append(fact)
    self.fact = nil
  }

  @MainActor
  func removeSavedFacts(atOffsets offsets: IndexSet) {
    self.savedFacts.remove(atOffsets: offsets)
  }
}

#Preview {
  OptionalPopovers()
}
