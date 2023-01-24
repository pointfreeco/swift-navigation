import CustomDump
import SwiftUI
import SwiftUINavigation
import XCTest

@MainActor
final class ButtonStateTests: XCTestCase {
  func testAsyncAnimationWarning() async {
    XCTExpectFailure {
      $0.compactDescription == """
        An animated action was performed asynchronously: …

          Action:
            ()

        Asynchronous actions cannot be animated. Evaluate this action in a synchronous closure, or \
        use 'SwiftUI.withAnimation' explicitly.
        """
    }

    let button = ButtonState(action: .send((), animation: .default)) {
      TextState("Animate!")
    }

    await button.withAction {
      await Task.yield()
    }
  }
}
