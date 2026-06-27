#if canImport(Testing) && CustomDump
  import CustomDump
  import Foundation
  import SwiftNavigation
  import SwiftUI
  import Testing

  struct ButtonStateTests {
    @Test
    func preferred() {
      let button = ButtonState(action: true) {
        TextState("OK")
      }

      #expect(!button.isPreferred)
      #expect(button.preferred().isPreferred)
      #expect(!button.preferred(false).isPreferred)
      #expect(button != button.preferred())

      var dump = ""
      customDump(button.preferred(), to: &dump)
      expectNoDifference(
        dump,
        """
        ButtonState(
          isPreferred: true,
          action: .send(
            true
          ),
          label: "OK"
        )
        """
      )
    }

    @Test
    func mapPreservesPreferred() {
      let button = ButtonState(action: 42) {
        TextState("OK")
      }
      .preferred()

      let mappedButton = button.map { action in
        action.map(String.init)
      }

      #expect(mappedButton.isPreferred)
    }

    @Test
    func testAsyncAnimationWarning() async {
      let button = ButtonState(action: .send((), animation: .easeInOut)) {
        TextState("Animate!")
      }

      await withKnownIssue {
        await button.withAction { _ in
          await Task.yield()
        }
      } matching: { issue in
        issue.description.hasSuffix(
          """
          An animated action was performed asynchronously: …

            Action:
              ButtonStateAction.send(
                (),
                animation: Animation.easeInOut
              )

          Asynchronous actions cannot be animated. Evaluate this action in a synchronous closure, \
          or use 'SwiftUI.withAnimation' explicitly.
          """
        )
      }
    }
  }
#endif
