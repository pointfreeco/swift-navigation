import SwiftUINavigation

struct OptionalNavigationLinks: View {
  @ObservedObject private var viewModel = ViewModel()

  var body: some View {
    List {
      Section {
        Stepper("Number: \(self.viewModel.count)", value: self.$viewModel.count)

        HStack {
          NavigationLink(unwrapping: self.$viewModel.fact) {
            self.viewModel.setFactNavigation(isActive: $0)
          } destination: { $fact in
            FactEditor(fact: $fact.description)
              .disabled(self.viewModel.isLoading)
              .foregroundColor(self.viewModel.isLoading ? .gray : nil)
              .navigationBarBackButtonHidden(true)
              .navigationBarItems(
                leading: Button("Cancel") {
                  self.viewModel.cancelButtonTapped()
                },
                trailing: Button("Save") {
                  self.viewModel.saveButtonTapped(fact: fact)
                }
              )
          } label: {
            Text("Get number fact")
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
    .navigationBarTitle("Links")
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
