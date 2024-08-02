import SwiftNavigation
import XCTest

class IsolationTests: XCTestCase {
  @MainActor
  func testIsolationOnMinActor() async {
    let model = MainActorModel()
    let expectation = expectation(description: "observation")
    expectation.expectedFulfillmentCount = 2
    let token = SwiftNavigation.observe {
      _ = model.count
      MainActor.assertIsolated()
      expectation.fulfill()
    }
    model.count += 1
    await fulfillment(of: [expectation], timeout: 1)
    _ = token
  }

  @GlobalActorIsolated
  func testIsolationOnGlobalActor() async {
    let model = GlobalActorModel()
    let expectation = expectation(description: "observation")
    expectation.expectedFulfillmentCount = 2
    let token = SwiftNavigation.observe {
      _ = model.count
      GlobalActorIsolated.assertIsolated()
      expectation.fulfill()
    }
    model.count += 1
    await fulfillment(of: [expectation], timeout: 1)
    _ = token
  }
}

@globalActor private actor GlobalActorIsolated: GlobalActor {
  static let shared = GlobalActorIsolated()
}

@Perceptible
@MainActor
class MainActorModel {
  var count = 0
}

@Perceptible
@GlobalActorIsolated
private class GlobalActorModel {
  var count = 0
}
