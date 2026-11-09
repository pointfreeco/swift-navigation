#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// `observe` called on an object keeps its observation for as long as the object lives, and never
  /// calls the closure again once the object is gone. That is what makes capturing the object
  /// `unowned` in the closure safe, as long as nothing else keeps the token alive.
  ///
  /// The closures here capture the owner weakly and count their calls, so that a broken guarantee
  /// fails the test instead of crashing the test process.
  final class ObserveLifetimeTests: XCTestCase {
    @MainActor
    func testObservationNeverCallsItsClosureOnceTheObjectIsGone() {
      let model = CounterModel()
      let recorder = CallRecorder()
      var owner: Owner? = Owner()
      owner?.observe { [weak owner] in
        _ = model.count
        recorder.record(isOwnerAlive: owner != nil)
      }
      weak var releasedOwner = owner

      owner = nil
      XCTAssertNil(releasedOwner, "The observation should not keep its object alive.")
      model.count += 1
      spinRunLoop(for: 0.1)

      XCTAssertEqual(recorder.callCount, 1, "Only the initial call should have happened.")
      XCTAssertEqual(recorder.callsAfterOwnerWasGone, 0)
    }

    /// The exception the documentation spells out: a token kept elsewhere keeps the observation,
    /// and its closure, going after the object is gone.
    @MainActor
    func testTokenKeptElsewhereKeepsCallingTheClosureAfterTheObjectIsGone() {
      let model = CounterModel()
      let recorder = CallRecorder()
      var owner: Owner? = Owner()
      let token = owner?.observe { [weak owner] in
        _ = model.count
        recorder.record(isOwnerAlive: owner != nil)
      }

      owner = nil
      model.count += 1
      spinRunLoop(for: 0.1)

      XCTAssertEqual(recorder.callsAfterOwnerWasGone, 1)
      withExtendedLifetime(token) {}
    }
  }

  @MainActor
  private final class Owner: NSObject {}

  @MainActor
  @Observable
  private final class CounterModel {
    var count = 0
  }

  @MainActor
  private final class CallRecorder {
    private(set) var callCount = 0
    private(set) var callsAfterOwnerWasGone = 0

    func record(isOwnerAlive: Bool) {
      callCount += 1
      if !isOwnerAlive {
        callsAfterOwnerWasGone += 1
      }
    }
  }
#endif
