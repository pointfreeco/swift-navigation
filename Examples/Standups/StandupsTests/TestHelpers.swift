import CasePaths
import Dependencies
import XCTest

// TODO: move this to swift-dependencies?
// Experiment with going back to having test context implicitly inferred, and have TCA detect
// stores running outside of test stores to opt out of inference
//
// document withTestValues in error that accesses live dep in test context
//
// test listener for first access of @Dependency? XCTestObservation
class DependencyTestCase: XCTestCase {
  override func invokeTest() {
    DependencyValues.withTestValues {
      super.invokeTest()
    }
  }
}
