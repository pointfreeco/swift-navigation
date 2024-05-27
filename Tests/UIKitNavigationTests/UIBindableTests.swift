import UIKitNavigation
import XCTest

@Perceptible
private final class Model {
  var text = ""
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
  func testEquatable() throws {
    let model = Model()
    @UIBindable var model1 = model
    @UIBindable var model2 = model
    XCTAssertEqual($model1, $model2)
    XCTAssertEqual($model1.text, $model2.text)
  }

  @MainActor
  func testEquatableHashable() throws {
    let model = Model()
    @UIBindable var model1 = model
    @UIBindable var model2 = model
    XCTAssertEqual($model1.hashValue, $model2.hashValue)
    XCTAssertEqual($model1.text.hashValue, $model2.text.hashValue)
  }
}
