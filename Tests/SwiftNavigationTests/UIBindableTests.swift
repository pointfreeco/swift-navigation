import SwiftNavigation
import XCTest

@Perceptible
private final class Model {
  var text = ""
  var title = ""
  var id: String { text }
}

final class UIBindableTests: XCTestCase {
  @MainActor
  func testDynamicMemberLookupBindable() throws {
    @UIBindable var model = Model()
    let textBinding = $model.text
    XCTAssert(type(of: textBinding) == UIBinding<String>.self)

    model.text = "Blob"
    XCTAssertEqual(model.text, "Blob")
    XCTAssertEqual(textBinding.wrappedValue, "Blob")

    textBinding.wrappedValue += ", Jr."
    XCTAssertEqual(model.text, "Blob, Jr.")
    XCTAssertEqual(textBinding.wrappedValue, "Blob, Jr.")
  }

  @MainActor
  func testEquatableHashable() throws {
    let model = Model()
    @UIBindable var model1 = model
    @UIBindable var model2 = model
    @UIBindable var model3 = Model()
    XCTAssertEqual(UIBindingIdentifier($model1.text), UIBindingIdentifier($model2.text))
    XCTAssertNotEqual(UIBindingIdentifier($model1.text), UIBindingIdentifier($model2.title))
    XCTAssertNotEqual(UIBindingIdentifier($model1.text), UIBindingIdentifier($model3.text))
    XCTAssertEqual(
      UIBindingIdentifier($model1.text).hashValue,
      UIBindingIdentifier($model2.text).hashValue
    )
    XCTAssertNotEqual(
      UIBindingIdentifier($model1.text).hashValue,
      UIBindingIdentifier($model2.title).hashValue
    )
    XCTAssertNotEqual(
      UIBindingIdentifier($model1.text).hashValue,
      UIBindingIdentifier($model3.text).hashValue
    )
  }
}
