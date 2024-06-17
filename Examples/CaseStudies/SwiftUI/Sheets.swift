import SwiftUI
import SwiftUINavigation

// TODO: optional destination
struct Sheets: SwiftUICaseStudy {
  let caseStudyTitle = "Optional navigation"
  let readMe = """
    This case study shows how to use an overload of SwiftUI's 'sheet(item:)' modifier that will \
    give you a binding to the data being presented, rather than just plain data.

    There are also similar view modifiers for the following other forms of navigation:

    * popover(item:)
    * fullScreenCover(item:)
    * navigationDestination(item:)
    """
  @State private var model = FeatureModel()

  var body: some View {
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
  @FocusState var isFocused: Bool

  var body: some View {
    VStack {
      TextEditor(text: $fact)
        .focused($isFocused)
    }
    .padding()
    .navigationTitle("Fact editor")
    .onAppear { isFocused = true }
  }
}

@Observable
private class FeatureModel {
  var count = 0
  var fact: Fact?
  var isLoading = false
  var savedFacts: [Fact] = []

  @MainActor
  func numberFactButtonTapped() async {
    isLoading = true
    defer { isLoading = false }
    self.fact = await getNumberFact(self.count)
  }

  @MainActor
  func cancelButtonTapped() {
    fact = nil
  }

  @MainActor
  func saveButtonTapped(fact: Fact) {
    savedFacts.append(fact)
    self.fact = nil
  }

  @MainActor
  func removeSavedFacts(atOffsets offsets: IndexSet) {
    savedFacts.remove(atOffsets: offsets)
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      Sheets()
    }
  }
}
