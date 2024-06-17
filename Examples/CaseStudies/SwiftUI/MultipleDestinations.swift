import SwiftUI
import SwiftUINavigation

@CasePathable
enum Destination {
  case alert(String)
  case confirmationDialog(String)
  case sheetWithPayload(Int)
  case sheetWithoutPayload
}

struct MultipleDestinations: SwiftUICaseStudy {
  let caseStudyTitle = "Concise enum navigation"
  let readMe = """
    This case study demonstrates how to power multiple forms of navigation from a single \
    destination enum that describes all of the possible destinations one can travel to from this \
    screen.
    
    The screen has four possible destinations: an alert, a confirmation dialog, and two kinds \
    of sheets. The state for each of these destinations is held as associated data of an enum, and \
    bindings to the cases of that enum are derived using the tools in this library.
    """
  @State var destination: Destination?
  
  var body: some View {
    Button("Alert") {
      destination = .alert("This is an alert!")
    }
    
    Button("Confirmation dialog") {
      destination = .confirmationDialog("This is a confirmation dialog!")
    }
    
    Button("Sheet with payload") {
      destination = .sheetWithPayload(.random(in: 1...1_000))
    }
    
    Button("Sheet without payload") {
      destination = .sheetWithoutPayload
    }
    .navigationTitle("Routing")
    .alert(item: $destination.alert) { title in
      Text(title)
    } actions: { _ in
    }
    .alert(item: $destination.confirmationDialog) { title in
      Text(title)
    } actions: { _ in
    }
    .sheet(item: $destination.sheetWithPayload, id: \.self) { $count in
      Form {
        Text(count.description)
        Button("Change count") {
          count = .random(in: 1...1_000)
        }
      }
      .navigationTitle("Sheet with payload")
    }
    .sheet(isPresented: Binding($destination.sheetWithoutPayload)) {
      Form {
        Text("Hello!")
      }
      .navigationTitle("Sheet with payload")
    }
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      MultipleDestinations()
    }
  }
}
