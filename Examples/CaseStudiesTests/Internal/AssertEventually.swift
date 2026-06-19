import CustomDump
import XCTest

@MainActor
func assertEventuallyEqual<T: Equatable>(
  _ expression1: @autoclosure () -> T,
  _ expression2: @autoclosure () -> T,
  timeout: TimeInterval = 1,
  file: StaticString = #file,
  line: UInt = #line
) async {
  await _assertEventually(
    expression1(),
    expression2(),
    condition: { $0 == $1 },
    assert: XCTAssertEqual,
    timeout: timeout,
    file: file,
    line: line
  )
}

@MainActor
func assertEventuallyNoDifference<T: Equatable>(
  _ expression1: @autoclosure () -> T,
  _ expression2: @autoclosure () -> T,
  timeout: TimeInterval = 1,
  file: StaticString = #file,
  line: UInt = #line
) async {
  await _assertEventually(
    expression1(),
    expression2(),
    condition: { $0 == $1 },
    assert: { lhs, rhs, message, file, line in
      expectNoDifference(
        lhs(),
        rhs(),
        message(),
        fileID: file,
        filePath: file,
        line: line,
        column: 0
      )
    },
    timeout: timeout,
    file: file,
    line: line
  )
}

@MainActor
func assertEventuallyNotEqual<T: Equatable>(
  _ expression1: @autoclosure () -> T,
  _ expression2: @autoclosure () -> T,
  timeout: TimeInterval = 1,
  file: StaticString = #file,
  line: UInt = #line
) async {
  await _assertEventually(
    expression1(),
    expression2(),
    condition: { $0 != $1 },
    assert: XCTAssertNotEqual,
    timeout: timeout,
    file: file,
    line: line
  )
}

@MainActor
func assertEventuallyNil<T>(
  _ expression: @autoclosure () -> T?,
  timeout: TimeInterval = 1,
  file: StaticString = #file,
  line: UInt = #line
) async {
  await _assertEventually(
    expression(),
    condition: { $0 == nil },
    assert: XCTAssertNil,
    timeout: timeout,
    file: file,
    line: line
  )
}

@MainActor
func assertEventuallyNotNil<T>(
  _ expression: @autoclosure () -> T?,
  timeout: TimeInterval = 1,
  file: StaticString = #file,
  line: UInt = #line
) async {
  await _assertEventually(
    expression(),
    condition: { $0 != nil },
    assert: XCTAssertNotNil,
    timeout: timeout,
    file: file,
    line: line
  )
}

@MainActor
private func _assertEventually<T>(
  _ expression1: @autoclosure () -> T,
  _ expression2: @autoclosure () -> T,
  condition: (T, T) -> Bool,
  assert: (
    @autoclosure () -> T,
    @autoclosure () -> T,
    @autoclosure () -> String,
    StaticString,
    UInt
  ) -> Void,
  timeout: TimeInterval,
  file: StaticString,
  line: UInt
) async {
  let start = Date()
  var value1 = expression1()
  var value2 = expression2()
  while !condition(value1, value2) {
    defer {
      value1 = expression1()
      value2 = expression2()
    }
    guard Date().timeIntervalSince(start) < timeout
    else {
      assert(value1, value2, "", file, line)
      return
    }
    await Task.yield()
  }
}

@MainActor
private func _assertEventually<T>(
  _ expression: @autoclosure () -> T,
  condition: (T) -> Bool,
  assert: (@autoclosure () -> T, @autoclosure () -> String, StaticString, UInt) -> Void,
  timeout: TimeInterval,
  file: StaticString,
  line: UInt
) async {
  let start = Date()
  var value = expression()
  while !condition(value) {
    defer {
      value = expression()
    }
    guard Date().timeIntervalSince(start) < timeout
    else {
      assert(value, "", file, line)
      return
    }
    await Task { try? await Task.sleep(nanoseconds: 1000) }.value
  }
}
