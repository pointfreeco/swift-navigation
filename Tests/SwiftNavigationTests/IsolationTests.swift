#if swift(>=6)
  import SwiftNavigation
  import XCTest

  class IsolationTests: XCTestCase {
    func testIsolationOnMainActor() async throws {
      await Task { @MainActor in
        let model = MainActorModel()
        var didObserve = false
        let token = SwiftNavigation.observe {
          _ = model.count
          MainActor.assertIsolated()
          didObserve = true
        }
        model.count += 1
        await Task.yield()
        XCTAssertEqual(didObserve, true)
        _ = token
      }
      .value
    }

    func testIsolationOnMainActor_derivedObservation() async throws {
      await Task { @MainActor in
        let model = MainActorModel()
        var didObserve = false
        let token = SwiftNavigation.observe {
          _ = model.count
          MainActor.assertIsolated()
        } onChange: {
          MainActor.assertIsolated()
          didObserve = true
        }
        model.count += 1
        await Task.yield()
        XCTAssertEqual(didObserve, true)
        _ = token
      }
      .value
    }

    func testIsolationOnGlobalActor() async throws {
      await Task { @GlobalActorIsolated in
        let model = GlobalActorModel()
        var didObserve = false
        let token = SwiftNavigation.observe {
          _ = model.count
          GlobalActorIsolated.assertIsolated()
          didObserve = true
        }
        model.count += 1
        await Task.yield()
        XCTAssertEqual(didObserve, true)
        _ = token
      }
      .value
    }

    func testIsolationOnGlobalActor_derivedObservation() async throws {
      await Task { @GlobalActorIsolated in
        let model = GlobalActorModel()
        var didObserve = false
        let token = SwiftNavigation.observe {
          _ = model.count
          GlobalActorIsolated.assertIsolated()
        } onChange: {
          GlobalActorIsolated.assertIsolated()
          didObserve = true
        }
        model.count += 1
        await Task.yield()
        XCTAssertEqual(didObserve, true)
        _ = token
      }
      .value
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
#endif
