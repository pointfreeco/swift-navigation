import SwiftUI

@available(iOS 15.0, *)
struct MyView: View {
  enum AlertAction {
    case usernameChanged(String)
    case passwordChanged(String)
    case loginButtonTapped
  }

  @State var alert: AlertState<AlertAction>?
  @State var username = ""
  @State var password = ""

  var body: some View {
    Button("Tap") {
      self.alert = AlertState {
        TextState("Log in")
      } actions: {
        TextFieldState(action: /AlertAction.usernameChanged) {
          Text("blob@pointfree.co")
        }
        SecureFieldState(action: /AlertAction.passwordChanged) {
          Text("••••••••")
        }
        ButtonState("")
      }



    }
    .alert(
      "Authentication required",
      isPresented: Binding(
        get: { self.alert != nil },
        set: { isPresented in
          if !isPresented {
            self.alert = nil
          }
        }
      )
    ) {

    } message: {
      Text("Please enter your login details.")
    }
  }
}

import CasePaths
import SwiftUI

@available(iOS 16, macOS 13, tvOS 16, watchOS 8, *)
public struct TextFieldState<Action> {
  public let initialText: String
  public let action: CasePath<Action, String>
  public let label: TextState

  public init(
    initialText: String = "",
    action: CasePath<Action, String>,
    label: () -> TextState
  ) {
    self.initialText = initialText
    self.action = action
    self.label = label()
  }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 8, *)
extension TextFieldState: ActionState {
  public typealias Value = String

  public func body(withAction perform: @escaping (Action) -> Void) -> some View {
    TextField(self, action: perform)
  }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 8, *)
extension TextField where Label == Text {
  public init<Action>(_ state: TextFieldState<Action>, action: @escaping (Action) -> Void) {
    var text = state.initialText
    self.init(
      text: Binding(
        get: { text },
        set: { newText in
          text = newText
          action(state.action.embed(newText))
        }
      )
    ) {
      Text(state.label)
    }
  }
}
