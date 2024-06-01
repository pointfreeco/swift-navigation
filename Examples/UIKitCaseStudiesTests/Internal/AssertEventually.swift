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
  var lhs = expression1()
  var rhs = expression2()
  while lhs != rhs {
    defer {
      lhs = expression1()
      rhs = expression2()
    }
    guard Date().timeIntervalSince(start) < timeout
    else {
      XCTAssertEqual(lhs, rhs, file: file, line: line)
      return
    }
    await Task.yield()
  }
}

@MainActor
func assertEventuallyNotEqual<T: Equatable>(
  _ expression1: @autoclosure @escaping @MainActor () -> T,
  _ expression2: @autoclosure @escaping @MainActor () -> T,
  timeout: TimeInterval = 2,
  file: StaticString = #file,
  line: UInt = #line
) async {
  let start = Date()
  var lhs = expression1()
  var rhs = expression2()
  while lhs == rhs {
    defer {
      lhs = expression1()
      rhs = expression2()
    }
    guard Date().timeIntervalSince(start) < timeout
    else {
      XCTAssertNotEqual(lhs, rhs, file: file, line: line)
      return
    }
    await Task.yield()
  }
}

@MainActor
func assertEventuallyNil<T>(
  _ expression: @autoclosure @escaping @MainActor () -> T?,
  timeout: TimeInterval = 2,
  file: StaticString = #file,
  line: UInt = #line
) async {
  let start = Date()
  var value = expression()
  while value != nil {
    defer {
      value = expression()
    }
    guard Date().timeIntervalSince(start) < timeout
    else {
      XCTAssertNil(value, file: file, line: line)
      return
    }
    await Task.yield()
  }
}

@MainActor
func assertEventuallyNotNil<T>(
  _ expression: @autoclosure @escaping @MainActor () -> T?,
  timeout: TimeInterval = 2,
  file: StaticString = #file,
  line: UInt = #line
) async {
  let start = Date()
  var value = expression()
  while value == nil {
    defer {
      value = expression()
    }
    guard Date().timeIntervalSince(start) < timeout
    else {
      XCTAssertNotNil(value, file: file, line: line)
      return
    }
    await Task.yield()
  }
}
