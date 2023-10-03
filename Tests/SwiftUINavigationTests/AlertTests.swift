#if canImport(SwiftUI)
  import CustomDump
  import SwiftUI
  import SwiftUINavigation
  import XCTest

  final class AlertTests: XCTestCase {
    func testAlertState() {
      let alert = AlertState(
        title: .init("Alert!"),
        message: .init("Something went wrong..."),
        primaryButton: .destructive(.init("Destroy"), action: .send(true, animation: .easeInOut)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(false))
      )
      XCTAssertNoDifference(
        alert,
        AlertState(
          title: .init("Alert!"),
          message: .init("Something went wrong..."),
          primaryButton: .destructive(.init("Destroy"), action: .send(true, animation: .easeInOut)),
          secondaryButton: .cancel(.init("Cancel"), action: .send(false))
        )
      )

      var dump = ""
      customDump(alert, to: &dump)
      XCTAssertNoDifference(
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
              action: .send(
                false
              ),
              label: "Cancel"
            )
          ],
          message: "Something went wrong..."
        )
        """
      )

      if #available(iOS 13, macOS 12, tvOS 13, watchOS 6, *) {
        dump = ""
        customDump(
          ConfirmationDialogState(
            title: .init("Alert!"),
            message: .init("Something went wrong..."),
            buttons: [
              .destructive(.init("Destroy"), action: .send(true, animation: .easeInOut)),
              .cancel(.init("Cancel"), action: .send(false)),
            ]
          ),
          to: &dump
        )
        XCTAssertNoDifference(
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
                action: .send(
                  false
                ),
                label: "Cancel"
              )
            ],
            message: "Something went wrong..."
          )
          """
        )
      }
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
        .alert(unwrapping: self.$alert) {
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
