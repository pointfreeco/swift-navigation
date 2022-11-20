import CustomDump
import SwiftUINavigation
import XCTest

final class AlertTests: XCTestCase {
  func testAlertState() {
    var dump = ""
    customDump(
      AlertState(
        title: .init("Alert!"),
        message: .init("Something went wrong..."),
        primaryButton: .destructive(.init("Destroy"), action: .send(true, animation: .default)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(false))
      ),
      to: &dump
    )
    XCTAssertNoDifference(
      dump,
      """
      AlertState(
        title: "Alert!",
        message: "Something went wrong...",
        buttons: [
          [0]: AlertState.Button.destructive(
            "Destroy",
            action: AlertState.ButtonAction.send(
              true,
              animation: Animation.easeInOut
            )
          ),
          [1]: AlertState.Button.cancel(
            "Cancel",
            action: AlertState.ButtonAction.send(false)
          )
        ]
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
            .destructive(.init("Destroy"), action: .send(true, animation: .default)),
            .cancel(.init("Cancel"), action: .send(false)),
          ]
        ),
        to: &dump
      )
      XCTAssertEqual(
        dump,
        """
        ConfirmationDialogState(
          title: "Alert!",
          message: "Something went wrong...",
          buttons: [
            [0]: AlertState.Button.destructive(
              "Destroy",
              action: AlertState.ButtonAction.send(
                true,
                animation: Animation.easeInOut
              )
            ),
            [1]: AlertState.Button.cancel(
              "Cancel",
              action: AlertState.ButtonAction.send(false)
            )
          ]
        )
        """
      )
    }
  }
}
