#if canImport(SwiftUI)
  import CustomDump
  import SwiftUI
  import SwiftNavigation
  import SwiftUINavigation
  import XCTest

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  final class AlertTests: XCTestCase {
    func testAlertState() {
      let alert = AlertState {
        TextState("Alert!")
      } actions: {
        ButtonState(role: .destructive, action: .send(true, animation: .easeInOut)) {
          TextState("Destroy")
        }
        ButtonState(role: .cancel) {
          TextState("Cancel")
        }
      } message: {
        TextState("Something went wrong...")
      }

      expectNoDifference(
        alert,
        AlertState {
          TextState("Alert!")
        } actions: {
          ButtonState(role: .destructive, action: .send(true, animation: .easeInOut)) {
            TextState("Destroy")
          }
          ButtonState(role: .cancel) {
            TextState("Cancel")
          }
        } message: {
          TextState("Something went wrong...")
        }
      )

      var dump = ""
      customDump(alert, to: &dump)
      expectNoDifference(
        dump,
        """
        AlertState(
          title: "Alert!",
          actions: [
            [0]: ButtonState(
              role: .destructive,
              action: .send(
                true,
                animation: Animation.easeInOut
              ),
              label: "Destroy"
            ),
            [1]: ButtonState(
              role: .cancel,
              action: .send(nil),
              label: "Cancel"
            )
          ],
          message: "Something went wrong..."
        )
        """
      )

      dump = ""
      customDump(
        ConfirmationDialogState {
          TextState("Alert!")
        } actions: {
          ButtonState(role: .destructive, action: .send(true, animation: .easeInOut)) {
            TextState("Destroy")
          }
          ButtonState(role: .cancel) {
            TextState("Cancel")
          }
        } message: {
          TextState("Something went wrong...")
        },
        to: &dump
      )
      expectNoDifference(
        dump,
        """
        ConfirmationDialogState(
          title: "Alert!",
          actions: [
            [0]: ButtonState(
              role: .destructive,
              action: .send(
                true,
                animation: Animation.easeInOut
              ),
              label: "Destroy"
            ),
            [1]: ButtonState(
              role: .cancel,
              action: .send(nil),
              label: "Cancel"
            )
          ],
          message: "Something went wrong..."
        )
        """
      )
    }
  }

  // NB: This is a compile time test to make sure that async action closures can be used in
  //     Swift <5.7.
  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  private struct TestView: View {
    @State var alert: AlertState<AlertAction>?
    enum AlertAction {
      case confirm
      case deny
    }

    var body: some View {
      Text("")
        .alert(self.$alert) {
          await self.alertButtonTapped($0)
        }
    }

    private func alertButtonTapped(_ action: AlertAction?) async {
      switch action {
      case .some(.confirm), .some(.deny), .none:
        break
      }
    }
  }
#endif  // canImport(SwiftUI)
