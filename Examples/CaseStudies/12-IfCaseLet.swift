import CasePaths
import SwiftUI
import SwiftUINavigation

private let readMe = """
  This demonstrates how to destructure a binding of an enum into a binding of one of its cases.

  Tap the "Edit" button to put the form into edit mode. Then you can make changes to the message \
  and either commit the changes by tapping "Save", or discard the changes by tapping "Discard".
  """

struct IfCaseLetCaseStudy: View {
  @State var string: String = "Hello"
  @State var editableString: EditableString = .inactive

  @CasePathable
  enum EditableString {
    case active(String)
    case inactive
  }

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }
      self.$editableString.active.map { $string in
        VStack {
          TextField("Edit string", text: $string)
          HStack {
            Button("Discard", role: .cancel) {
              self.editableString = .inactive
            }
            Spacer()
            Button("Save") {
              self.string = string
              self.editableString = .inactive
            }
          }
        }
      }
      if !self.editableString.is(\.active) {
        Text("\(self.string)")
        Button("Edit") {
          self.editableString = .active(self.string)
        }
      }
    }
    .buttonStyle(.borderless)
  }
}

#Preview {
  IfCaseLetCaseStudy()
}
