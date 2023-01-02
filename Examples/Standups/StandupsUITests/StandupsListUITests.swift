import XCTest

// This test case demonstrates how one can write UI tests using the swift-dependencies library.
// We do not really recommend writing UI tests in general as they are slow and flakey, but if you
// must then this shows how.
//
// The key to doing this is to set a launch environment variable on your XCUIApplication instance,
// and then check for that value in the entry point of the application. If the environment value
// exists, you can use 'withDependencies' to override dependencies to be used in the UI test.
final class StandupsListUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUpWithError() throws {
    self.continueAfterFailure = false
    self.app = XCUIApplication()
    app.launchEnvironment = [
      "UITesting": "true"
    ]
  }

  // This test demonstrates the simple flow of tapping the "Add" button, filling in some fields
  // in the form, and then adding the standup to the list. It's a very simple test, but it takes
  // over 15 seconds to run, and it depends on a lot of internal implementation details to get
  // right, such as tapping a button with the literal label "Add".
  //
  // This test is also written in the simpler, "unit test" style in StandupsListTests.swift, where
  // it takes 0.025 seconds (600 times faster) and it even tests more. It further confirms that
  // when the standup is added to the list its data will be persisted to disk so that it will be
  // available on next launch.
  func testAdd() throws {
    app.launch()
    app.navigationBars["Daily Standups"].buttons["Add"].tap()
    let collectionViews = app.collectionViews
    let nameTextField = collectionViews.textFields["Name"]

    // NB: Fails if keyboard is not visible.
    app.keys["E"].tap()
    app.keys["n"].tap()
    app.keys["g"].tap()
    app.keys["i"].tap()
    app.keys["n"].tap()
    app.keys["e"].tap()
    app.keys["e"].tap()
    app.keys["r"].tap()
    app.keys["i"].tap()
    app.keys["n"].tap()
    app.keys["g"].tap()

    nameTextField.tap()
    app.keys["B"].tap()
    app.keys["l"].tap()
    app.keys["o"].tap()
    app.keys["b"].tap()

    collectionViews.buttons["New attendee"].tap()
    app.keys["B"].tap()
    app.keys["l"].tap()
    app.keys["o"].tap()
    app.keys["b"].tap()
     app.keys["space"].tap()
    app.keys["j"].tap() // TODO: How to type a capital "J"?
    app.keys["r"].tap()
    // TODO: How to type a "."?

    app.navigationBars["New standup"].buttons["Add"].tap()

    XCTAssertEqual(collectionViews.staticTexts["engineering"].exists, true)
  }

  // TODO: can we figure this out?
//  func testAdd_Faster() throws {
//    app.launch()
//    app.navigationBars["Daily Standups"]/*@START_MENU_TOKEN@*/.buttons["Add"]/*[[".otherElements[\"Add\"].buttons[\"Add\"]",".buttons[\"Add\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//    let collectionViews = app.collectionViews
//    let titleTextField = collectionViews.textFields["Title"]
//    let nameTextField = collectionViews.textFields["Name"]
//
//    titleTextField.typeText("Engineering")
//    nameTextField.tap()
//    nameTextField.typeText("Blob")
//    collectionViews.buttons["New attendee"].tap()
//    collectionViews.textFields.element(boundBy: 0).typeText("Blob Jr.")
//
//    app.navigationBars["New standup"].buttons["Add"].tap()
//
//    XCTAssertEqual(collectionViews.staticTexts["Engineering"].exists, true)
//  }
}
