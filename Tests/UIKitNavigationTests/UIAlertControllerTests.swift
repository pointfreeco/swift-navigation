#if canImport(UIKit) && !os(watchOS)
  import UIKitNavigation
  import XCTest

  @available(iOS 13, tvOS 13, *)
  final class UIAlertControllerTests: XCTestCase {
    @MainActor
    func testAlertPreferredAction() {
      let controller = UIAlertController(
        state: AlertState {
          TextState("Title")
        } actions: {
          ButtonState(action: 1) {
            TextState("First")
          }
          ButtonState(action: 2) {
            TextState("Second")
          }
          .preferred()
        }
      )

      XCTAssertTrue(controller.preferredAction === controller.actions[1])
    }

    @MainActor
    func testConfirmationDialogPreferredAction() {
      let controller = UIAlertController(
        state: ConfirmationDialogState {
          TextState("Title")
        } actions: {
          ButtonState(action: 1) {
            TextState("First")
          }
          ButtonState(action: 2) {
            TextState("Second")
          }
          .preferred()
        }
      )

      XCTAssertTrue(controller.preferredAction === controller.actions[1])
    }

    @MainActor
    func testMultiplePreferredActionsReportIssueAndUseFirstPreferredAction() {
      var controller: UIAlertController?

      XCTExpectFailure {
        controller = UIAlertController(
          state: ConfirmationDialogState {
            TextState("Title")
          } actions: {
            ButtonState(action: 1) {
              TextState("First")
            }
            .preferred()
            ButtonState(action: 2) {
              TextState("Second")
            }
            .preferred()
          }
        )
      } issueMatcher: {
        $0.compactDescription
          == """
          failed - 'UIAlertController' received 'ConfirmationDialogState' with multiple preferred buttons. Will use the first preferred button.
          """
      }

      guard let controller else {
        XCTFail("Expected a controller.")
        return
      }
      XCTAssertTrue(controller.preferredAction === controller.actions[0])
    }
  }
#endif
