import CasePaths
import Dependencies
import XCTest

// TODO: move this to swift-case-paths?
public func XCTUnwrap<Root, Case>(
  _ root: Root,
  case casePath: CasePath<Root, Case>
) throws -> Case {
  guard let value = casePath.extract(from: root)
  else {
    throw CaseDoesNotMatch()
  }
  return value
}
private struct CaseDoesNotMatch: Error {}

// TODO: move this to swift-dependencies?
class BaseTestCase: XCTestCase {
  override func invokeTest() {
    DependencyValues.withTestValues {
      super.invokeTest()
    }
  }
}
