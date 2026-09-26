#if canImport(SwiftUI)
  import SwiftNavigation
  import SwiftUI
  import XCTest

  final class LocalizedStringKeyTests: XCTestCase {
    func testTextStateLocalizedStringKeyWithUnexpectedStorageDoesNotCrash() {
      let text = TextState("\(AttributedString("Hello, world!"))")
      XCTAssertFalse(String(state: text).isEmpty)
    }
  }
#endif
