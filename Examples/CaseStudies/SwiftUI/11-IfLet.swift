import SwiftUI
import SwiftUINavigation

private let readMe = """
  This demonstrates how to unwrap a binding of an optional into a binding of an honest value.

  Tap the "Edit" button to put the form into edit mode. Then you can make changes to the message \
  and either commit the changes by tapping "Save", or discard the changes by tapping "Discard".
  """

struct IfLetCaseStudy: View {
  @State var string: String = "Hello"
  @State var editableString: String?

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }
      Binding(unwrapping: $editableString).map { $string in
        VStack {
          TextField("Edit string", text: $string)
          HStack {
            Button("Discard") {
              editableString = nil
            }
            Spacer()
            Button("Save") {
              string = string
              editableString = nil
            }
          }
        }
      }
      if editableString == nil {
        Text("\(string)")
        Button("Edit") {
          editableString = string
        }
      }
    }
    .buttonStyle(.borderless)
  }
}

#Preview {
  IfLetCaseStudy()
}
