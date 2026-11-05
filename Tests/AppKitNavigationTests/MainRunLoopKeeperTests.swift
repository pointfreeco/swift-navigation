#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import Foundation
  import Testing

  @Suite struct MainRunLoopKeeperTests {
    /// How the exit test's child process ends when it gets past the stray stop.
    static let finishedExitCode: CInt = 42

    /// Stands in for the stop an AppKit event loop occasionally leaves for the outermost run loop:
    /// the child process stops the main run loop, then needs it again to finish.
    @Test(
      "a stray stop of the main run loop does not end the test process",
      .enabled("Only Swift's async main ends the process when its run loop stops") {
        await MainRunLoopKeeper.isNeeded
      }
    )
    func strayStopDoesNotEndTheProcess() async {
      await #expect(processExitsWith: .exitCode(MainRunLoopKeeperTests.finishedExitCode)) {
        await MainRunLoopKeeper.start()
        await MainActor.run {
          CFRunLoopStop(CFRunLoopGetMain())
        }
        // NB: Only a running main run loop gets back to the main actor.
        await MainActor.run {}
        exit(MainRunLoopKeeperTests.finishedExitCode)
      }
    }
  }
#endif
