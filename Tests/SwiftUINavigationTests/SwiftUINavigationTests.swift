#if canImport(SwiftUI)
  import SwiftUI
  import XCTest

  @testable import SwiftUINavigation

  final class SwiftUINavigationTests: XCTestCase {
    func testBindingUnwrap() throws {
      var value: Int?
      let binding = Binding(get: { value }, set: { value = $0 })

      XCTAssertNil(Binding(unwrapping: binding))

      binding.wrappedValue = 1
      let unwrapped = try XCTUnwrap(Binding(unwrapping: binding))
      XCTAssertEqual(binding.wrappedValue, 1)
      XCTAssertEqual(unwrapped.wrappedValue, 1)

      unwrapped.wrappedValue = 42
      XCTAssertEqual(binding.wrappedValue, 42)
      XCTAssertEqual(unwrapped.wrappedValue, 42)

      binding.wrappedValue = 1729
      XCTAssertEqual(binding.wrappedValue, 1729)
      XCTAssertEqual(unwrapped.wrappedValue, 1729)

      binding.wrappedValue = nil
      XCTAssertEqual(binding.wrappedValue, nil)
      XCTAssertEqual(unwrapped.wrappedValue, 1729)
    }

    func testBindingCase() throws {
      struct MyError: Error, Equatable {}
      var value: Result<Int, MyError>? = nil
      let binding = Binding(get: { value }, set: { value = $0 })

      let success = binding.case(/Result.success)
      let failure = binding.case(/Result.failure)
      XCTAssertEqual(binding.wrappedValue, nil)
      XCTAssertEqual(success.wrappedValue, nil)
      XCTAssertEqual(failure.wrappedValue, nil)

      binding.wrappedValue = .success(1)
      XCTAssertEqual(binding.wrappedValue, .success(1))
      XCTAssertEqual(success.wrappedValue, 1)
      XCTAssertEqual(failure.wrappedValue, nil)

      success.wrappedValue = 42
      XCTAssertEqual(binding.wrappedValue, .success(42))
      XCTAssertEqual(success.wrappedValue, 42)
      XCTAssertEqual(failure.wrappedValue, nil)

      failure.wrappedValue = MyError()
      XCTAssertEqual(binding.wrappedValue, .failure(MyError()))
      XCTAssertEqual(success.wrappedValue, nil)
      XCTAssertEqual(failure.wrappedValue, MyError())

      success.wrappedValue = nil
      XCTAssertEqual(binding.wrappedValue, nil)
      XCTAssertEqual(success.wrappedValue, nil)
      XCTAssertEqual(failure.wrappedValue, nil)
    }
  }
#endif  // canImport(SwiftUI)
