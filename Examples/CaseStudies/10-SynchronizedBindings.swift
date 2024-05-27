import SwiftUI
import SwiftUINavigation

private let readMe = """
  This demonstrates how to synchronize model state with view state using the "bind" view modifier. \
  The model starts focused on the "Username" field, which is immediately focused when the form \
  first appears. When you tap the "Sign in" button, the focus will change to the first non-empty \
  field.
  """

struct SynchronizedBindings: View {
  @FocusState private var focusedField: FeatureModel.Field?
  @State private var model = FeatureModel()

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }

      Section {
        TextField("Username", text: $model.username)
          .focused($focusedField, equals: .username)

        SecureField("Password", text: $model.password)
          .focused($focusedField, equals: .password)

        Button("Sign In") {
          model.signInButtonTapped()
        }
        .buttonStyle(.borderedProminent)
      }
      .textFieldStyle(.roundedBorder)
    }
    .bind($model.focusedField, to: $focusedField)
    .navigationTitle("Synchronized focus")
  }
}

@Observable
private class FeatureModel {
  enum Field: String {
    case username
    case password
  }

  var focusedField: Field? = .username
  var password: String = ""
  var username: String = ""

  func signInButtonTapped() {
    if username.isEmpty {
      focusedField = .username
    } else if password.isEmpty {
      focusedField = .password
    } else {
      focusedField = nil
    }
  }
}

#Preview {
  SynchronizedBindings()
}
