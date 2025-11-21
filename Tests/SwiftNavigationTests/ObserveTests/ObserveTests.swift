import SwiftNavigation
import Perception
import XCTest
import ConcurrencyExtras

class ObserveTests: XCTestCase {
  #if swift(>=6)
    func testSimpleObserve() async {
      await MainActor.run {
        var count = 0
        let token = SwiftNavigation.observe {
          count = 1
        }
        XCTAssertEqual(count, 1)
        _ = token
      }
    }

    func testScopedObserve() async {
      await MainActor.run {
        var count = 0
        let token = SwiftNavigation.observe {
          count = 1
        } onChange: {
          count = 2
        }
        // onChange is called after invoking the context
        XCTAssertEqual(count, 2)
        _ = token
      }
    }

    func testNestedObserve() async {
      let a = A()

      nonisolated(unsafe) var value: Int = 0
      nonisolated(unsafe) var outerCount: Int = 0
      nonisolated(unsafe) var innerCount: Int = 0
      nonisolated(unsafe) var innerToken: ObserveToken?

      let outerToken = SwiftNavigation.observe {
        outerCount += 1
        let b = a.b

        if innerToken == nil {
          innerToken = SwiftNavigation.observe {
            // The problem: Outer observe tracks those changes
            value = b.value
            innerCount += 1
          }
        }
      }

      // a.b doesn't change here
      a.b.value += 1

      // Those are not enough to perform updates:
      // await Task.yeild()
      // await Task.megaYeild()
      // Falling back to Task.sleep
      try? await Task.sleep(nanoseconds: UInt64(0.5 * pow(10, 9)))

      XCTAssertEqual(value, 1)

      // Expected unscoped behavior, that can be optimized
      // with observation scoping
      XCTAssertEqual(outerCount, 2) // redundant update
      XCTAssertEqual(innerCount, 2) // initial value + updated value
      _ = outerToken
      _ = innerToken
    }

  func testScopedNestedObserve() async {
    let a = A()

    nonisolated(unsafe) var value: Int = 0
    nonisolated(unsafe) var outerCount: Int = 0
    nonisolated(unsafe) var innerCount: Int = 0
    nonisolated(unsafe) var innerToken: ObserveToken?

    let outerToken = SwiftNavigation.observe { _ = a.b } onChange: {
      outerCount += 1
      let b = a.b

      if innerToken == nil {
        innerToken = SwiftNavigation.observe { _ = b.value } onChange: {
          value = b.value
          innerCount += 1
        }
      }
    }

    a.b.value += 1

    // Those are not enough to perform updates:
    // await Task.yield()
    // await Task.megaYield()
    // Falling back to Task.sleep
    try? await Task.sleep(nanoseconds: UInt64(0.5 * pow(10, 9)))

    XCTAssertEqual(value, 1)
    XCTAssertEqual(outerCount, 1) // no redundant updates here
    XCTAssertEqual(innerCount, 2) // initial value + updated value
    _ = outerToken
    _ = innerToken
  }
  #endif

  #if !os(WASI)
    @MainActor
    func testTokenStorage() async {
      var count = 0
      var tokens: Set<ObserveToken> = []

      observe {
        count += 1
      }
      .store(in: &tokens)

      observe {
        count += 1
      }
      .store(in: &tokens)

      XCTAssertEqual(count, 2)
    }
  #endif
}

@Perceptible
fileprivate class A: @unchecked Sendable {
  var b: B = .init()
}

@Perceptible
fileprivate class B: @unchecked Sendable {
  var value: Int = 0
}


