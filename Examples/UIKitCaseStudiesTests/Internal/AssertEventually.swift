import XCTest

@MainActor
func assertEventually(
  _ condition: @Sendable @MainActor () -> Bool,
  timeout: TimeInterval = 2,
  file: StaticString = #file,
  line: UInt = #line
) async {
  let start = Date()
  while !condition() {
    guard Date().timeIntervalSince(start) < timeout
    else {
      XCTFail("Condition not met after \(timeout) seconds.", file: file, line: line)
      return
    }
    await Task.yield()
  }
}

@MainActor
func assertEventuallyEqual<T: Equatable>(
  _ expression1: @autoclosure @escaping @MainActor () -> T,
  _ expression2: @autoclosure @escaping @MainActor () -> T,
  timeout: TimeInterval = 2,
  file: StaticString = #file,
  line: UInt = #line
) async {
  let start = Date()
  while expression1() != expression2() {
    guard Date().timeIntervalSince(start) < timeout
    else {
      XCTAssertEqual(expression1(), expression2(), file: file, line: line)
      return
    }
    await Task.yield()
  }
}
