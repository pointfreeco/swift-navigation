import SwiftUI
import SwiftUINavigation

struct NavigationDestinations: SwiftUICaseStudy {
  let caseStudyTitle = "Navigation destination"
  let readMe = """
    This case study shows how to use an overload of SwiftUI's 'navigationDestination(item:)' \
    modifier that will give you a binding to the data being presented, rather than just plain data.
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
  @FocusState var isFocused

  var body: some View {
    VStack {
      TextEditor(text: $fact)
        .focused($isFocused)
    }
    .padding()
    .navigationBarTitle("Fact Editor")
    .onAppear { isFocused = true }
  }
}

@Observable
@MainActor
private class FeatureModel {
  var count = 0
  var fact: Fact?
  var isLoading = false
  var savedFacts: [Fact] = []

  func setFactNavigation(isActive: Bool) async {
    if isActive {
      isLoading = true
      defer { isLoading = false }
      self.fact = await getNumberFact(self.count)
    } else {
      fact = nil
    }
  }

  func numberFactButtonTapped() async {
    await setFactNavigation(isActive: true)
  }

  func cancelButtonTapped() async {
    await setFactNavigation(isActive: false)
  }

  func saveButtonTapped(fact: Fact) async {
    savedFacts.append(fact)
    await setFactNavigation(isActive: false)
  }

  func removeSavedFacts(atOffsets offsets: IndexSet) {
    savedFacts.remove(atOffsets: offsets)
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      NavigationDestinations()
    }
  }
}
