#if canImport(SwiftUI)
  import CustomDump
  import SwiftUI
  import SwiftUINavigation
  import XCTest

  final class ButtonStateTests: XCTestCase {
    func testAsyncAnimationWarning() async {
      XCTExpectFailure {
        $0.compactDescription == """
          failed - An animated action was performed asynchronously: …

            Action:
              ButtonStateAction.send(
                (),
                animation: Animation.easeInOut
              )

          Asynchronous actions cannot be animated. Evaluate this action in a synchronous closure, or \
          use 'SwiftUI.withAnimation' explicitly.
          """
      }

      let button = ButtonState(action: .send((), animation: .easeInOut)) {
        TextState("Animate!")
      }

      await button.withAction { _ in
        await Task.yield()
      }
    }
  }
#endif  // canImport(SwiftUI)
