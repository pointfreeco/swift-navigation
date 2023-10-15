import SwiftUI
import SwiftUINavigation

private let readMe = """
  This demonstrates to use the IfLet view to unwrap a binding of an optional into a binding of \
  an honest value.

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
      IfLet(self.$editableString) { $string in
        TextField("Edit string", text: $string)
        HStack {
          Button("Discard") {
            self.editableString = nil
          }
          Button("Save") {
            self.string = string
            self.editableString = nil
          }
        }
      } else: {
        Text("\(self.string)")
        Button("Edit") {
          self.editableString = self.string
        }
      }
      .buttonStyle(.borderless)
    }
  }
}

#Preview {
  IfLetCaseStudy()
}
