#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKitNavigation
  import XCTest

  final class NSProgressIndicatorTests: XCTestCase {
    /// Records animation requests instead of running them, so the binding can be observed without
    /// a window or a run loop.
    private final class SpyProgressIndicator: NSProgressIndicator {
      nonisolated(unsafe) var animationRequests: [Bool] = []

      override func startAnimation(_ sender: Any?) {
        animationRequests.append(true)
      }

      override func stopAnimation(_ sender: Any?) {
        animationRequests.append(false)
      }
    }

    /// The binding used to stop working as soon as the caller discarded the returned token: the
    /// token was freshly created and retained by nobody, so it deallocated at the end of the
    /// statement and cancelled the observation behind it.
    @MainActor
    func testKeepsObservingWhenTheTokenIsDiscarded() async {
      @UIBinding var isAnimated = false
      let progressIndicator = SpyProgressIndicator()

      progressIndicator.bind(isAnimated: $isAnimated)
      XCTAssertEqual(progressIndicator.animationRequests, [false])

      isAnimated = true
      await Task.yield()
      XCTAssertEqual(progressIndicator.animationRequests, [false, true])

      isAnimated = false
      await Task.yield()
      XCTAssertEqual(progressIndicator.animationRequests, [false, true, false])
    }

    @MainActor
    func testUnbindStopsObserving() async {
      @UIBinding var isAnimated = false
      let progressIndicator = SpyProgressIndicator()

      progressIndicator.bind(isAnimated: $isAnimated)
      progressIndicator.unbindIsAnimated()

      isAnimated = true
      await Task.yield()
      XCTAssertEqual(progressIndicator.animationRequests, [false])
    }

    @MainActor
    func testRebindingReplacesThePreviousBinding() async {
      @UIBinding var first = false
      @UIBinding var second = false
      let progressIndicator = SpyProgressIndicator()

      progressIndicator.bind(isAnimated: $first)
      progressIndicator.bind(isAnimated: $second)
      progressIndicator.animationRequests.removeAll()

      first = true
      await Task.yield()
      XCTAssertEqual(progressIndicator.animationRequests, [], "the replaced binding must be silent")

      second = true
      await Task.yield()
      XCTAssertEqual(progressIndicator.animationRequests, [true])
    }
  }
#endif
