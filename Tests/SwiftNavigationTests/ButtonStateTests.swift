#if canImport(Testing)
  import CustomDump
  import SwiftNavigation
  import Testing

  struct ButtonStateTests {
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
        issue.description == """
          Expectation failed: An animated action was performed asynchronously: …

            Action:
              ButtonStateAction.send(
                (),
                animation: Animation.easeInOut
              )

          Asynchronous actions cannot be animated. Evaluate this action in a synchronous closure, \
          or use 'SwiftUI.withAnimation' explicitly.
          """
      }
    }
  }
#endif
