import SwiftUINavigation

struct OptionalPopovers: View {
  @ObservedObject private var viewModel = ViewModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(self.viewModel.count)", value: self.$viewModel.count)

        HStack {
          Button("Get number fact") {
            self.viewModel.numberFactButtonTapped()
          }
          .popover(
            unwrapping: self.$viewModel.fact,
            arrowEdge: .bottom
          ) { $fact in
            NavigationView {
              FactEditor(fact: $fact.description)
                .disabled(self.viewModel.isLoading)
                .foregroundColor(self.viewModel.isLoading ? .gray : nil)
                .navigationBarItems(
                  leading: Button("Cancel") {
                    self.viewModel.cancelButtonTapped()
                  },
                  trailing: Button("Save") {
                    self.viewModel.saveButtonTapped(fact: fact)
                  }
                )
            }
          }

          if self.viewModel.isLoading {
            Spacer()
            ProgressView()
          }
        }
      } header: {
        Text("Fact Finder")
      }

      Section {
        ForEach(self.viewModel.savedFacts) { fact in
          Text(fact.description)
        }
        .onDelete { self.viewModel.removeSavedFacts(atOffsets: $0) }
      } header: {
        Text("Saved Facts")
      }
    }
    .navigationBarTitle("Sheets")
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

private class ViewModel: ObservableObject {
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
