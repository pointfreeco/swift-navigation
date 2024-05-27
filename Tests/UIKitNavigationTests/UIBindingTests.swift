import UIKitNavigation
import XCTest

final class UIBindingTests: XCTestCase {
  @MainActor
  func testInitProjectedValue() throws {
    @UIBinding var text = ""
    let textBinding = UIBinding(projectedValue: $text)

    text = "Blob"
    XCTAssertEqual(text, "Blob")
    XCTAssertEqual(textBinding.wrappedValue, "Blob")

    textBinding.wrappedValue += ", Jr."
    XCTAssertEqual(text, "Blob, Jr.")
    XCTAssertEqual(textBinding.wrappedValue, "Blob, Jr.")
  }

  @MainActor
  func testOperationFromOptional() throws {
    @UIBinding var count: Int? = nil

    XCTAssertNil(UIBinding($count))

    count = 42
    let unwrappedCountBinding = try XCTUnwrap(UIBinding($count))
    XCTAssertEqual(count, 42)
    XCTAssertEqual(unwrappedCountBinding.wrappedValue, 42)

    count? += 1
    XCTAssertEqual(count, 43)
    XCTAssertEqual(unwrappedCountBinding.wrappedValue, 43)

    unwrappedCountBinding.wrappedValue += 1
    XCTAssertEqual(count, 44)
    XCTAssertEqual(unwrappedCountBinding.wrappedValue, 44)

    count = nil
    XCTAssertEqual(count, nil)
    XCTAssertEqual(unwrappedCountBinding.wrappedValue, 44)

    unwrappedCountBinding.wrappedValue += 1
    XCTAssertEqual(count, nil)
    XCTAssertEqual(unwrappedCountBinding.wrappedValue, 45)

    count = 1729
    XCTAssertEqual(count, 1729)
    XCTAssertEqual(unwrappedCountBinding.wrappedValue, 1729)
  }

  @MainActor
  func testOperationToOptional() {
    @UIBinding var count = 0

    let optionalCountBinding = UIBinding<Int?>($count)

    count += 1
    XCTAssertEqual(count, 1)
    XCTAssertEqual(optionalCountBinding.wrappedValue, 1)

    optionalCountBinding.wrappedValue? += 1
    XCTAssertEqual(count, 2)
    XCTAssertEqual(optionalCountBinding.wrappedValue, 2)

    optionalCountBinding.wrappedValue = nil
    XCTAssertEqual(count, 2)
    XCTAssertEqual(optionalCountBinding.wrappedValue, 2)
  }

//  @MainActor
//  func testOperationToAnyHashable() {
//    @UIBinding var count = 0
//
//    let optionalCountBinding = UIBinding<AnyHashable>($count)
//    XCTAssertEqual(count, 0)
//    XCTAssertEqual(optionalCountBinding.wrappedValue, 0)
//
//    count += 1
//    XCTAssertEqual(count, 1)
//    XCTAssertEqual(optionalCountBinding.wrappedValue, 1)
//
//    optionalCountBinding.wrappedValue = 2
//    XCTAssertEqual(count, 2)
//    XCTAssertEqual(optionalCountBinding.wrappedValue, 2)
//  }

  @MainActor
  func testOperationConstant() {
    @UIBinding var count: Int
    _count = .constant(0)

    count += 1
    XCTAssertEqual(count, 0)
  }

  @MainActor
  func testDynamicMemberLookupProperty() {
    struct User {
      var name = ""
    }
    @UIBinding var user = User()

    let nameBinding = $user.name

    user.name = "Blob"
    XCTAssertEqual(user.name, "Blob")
    XCTAssertEqual(nameBinding.wrappedValue, "Blob")

    nameBinding.wrappedValue += ", Jr."
    XCTAssertEqual(user.name, "Blob, Jr.")
    XCTAssertEqual(nameBinding.wrappedValue, "Blob, Jr.")
  }

  @MainActor
  func testDynamicMemberLookupCase() throws {
    struct Failure: Error, Equatable {}

    @UIBinding var result: Result<Int, Failure> = .success(0)

    XCTAssertNil($result.failure)

    let countBinding = try XCTUnwrap($result.success)
    XCTAssertEqual(result, .success(0))
    XCTAssertEqual(countBinding.wrappedValue, 0)

    result = .success(42)
    XCTAssertEqual(result, .success(42))
    XCTAssertEqual(countBinding.wrappedValue, 42)

    countBinding.wrappedValue += 1
    XCTAssertEqual(result, .success(43))
    XCTAssertEqual(countBinding.wrappedValue, 43)

    result = .failure(Failure())
    XCTAssertEqual(result, .failure(Failure()))
    XCTAssertEqual(countBinding.wrappedValue, 43)

    countBinding.wrappedValue += 1
    XCTAssertEqual(result, .failure(Failure()))
    XCTAssertEqual(countBinding.wrappedValue, 44)

    result = .success(1729)
    XCTAssertEqual(result, .success(1729))
    XCTAssertEqual(countBinding.wrappedValue, 1729)
  }

  @MainActor
  func testDynamicMemberLookupOptionalEnumCase() throws {
    struct Failure: Error, Equatable {}

    @UIBinding var result: Result<Int, Failure>? = .success(0)

    XCTAssertNil($result.failure.wrappedValue)

    let countBinding = try XCTUnwrap($result.success)
    XCTAssertEqual(result, .success(0))
    XCTAssertEqual(countBinding.wrappedValue, 0)

    result = .success(42)
    XCTAssertEqual(result, .success(42))
    XCTAssertEqual(countBinding.wrappedValue, 42)

    countBinding.wrappedValue? += 1
    XCTAssertEqual(result, .success(43))
    XCTAssertEqual(countBinding.wrappedValue, 43)

    countBinding.wrappedValue = nil
    XCTAssertNil(result)
    XCTAssertNil(countBinding.wrappedValue)

    result = .failure(Failure())
    XCTAssertEqual(result, .failure(Failure()))
    XCTAssertNil(countBinding.wrappedValue)

    countBinding.wrappedValue? += 1
    XCTAssertEqual(result, .failure(Failure()))
    XCTAssertNil(countBinding.wrappedValue)

    countBinding.wrappedValue = nil
    XCTAssertEqual(result, .failure(Failure()))
    XCTAssertNil(countBinding.wrappedValue)

    result = .success(1729)
    XCTAssertEqual(result, .success(1729))
    XCTAssertEqual(countBinding.wrappedValue, 1729)
  }
}
