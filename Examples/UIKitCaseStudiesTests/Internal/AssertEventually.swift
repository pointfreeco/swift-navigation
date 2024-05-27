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
