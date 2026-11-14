#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import Foundation
  #if compiler(<6.4)
    // NB: Swift 6.2 treats the trait's conformance to 'SuiteTrait' below as public, and a public
    //     conformance needs a public import.
    public import Testing
  #else
    import Testing
  #endif

  /// A trait that keeps the main run loop running when an AppKit event loop leaves a stray stop
  /// behind.
  ///
  /// `swift test` runs Swift Testing in a process whose `async` main runs the main run loop and
  /// calls `exit(0)` as soon as that run loop returns. Some AppKit calls run a nested event loop —
  /// `performClick(_:)` on a segmented control, creating a save or open panel — and occasionally
  /// leave a `CFRunLoopStop` that reaches the outermost run loop instead. The process then ends
  /// partway through with status 0, and the tests that had not run yet are never reported.
  ///
  /// The testing library prepares the traits of every test before it runs any of them, so this
  /// trait protects the whole process even if only one suite has it. Add it to every suite whose
  /// tests drive an AppKit event loop anyway, so that it shows which suites need it.
  struct KeepsMainRunLoopRunningTrait: SuiteTrait {
    func prepare(for test: Test) async throws {
      await MainRunLoopKeeper.start()
    }
  }

  extension Trait where Self == KeepsMainRunLoopRunningTrait {
    /// Keeps the main run loop running when an AppKit event loop leaves a stray stop behind.
    static var keepsMainRunLoopRunning: Self { Self() }
  }

  /// Restarts the main run loop when the run loop Swift's `async` main is running gets stopped.
  @MainActor
  enum MainRunLoopKeeper {
    private static var isStarted = false

    /// How many activations of the main run loop in its common modes are running, counting the one
    /// Swift's `async` main runs.
    private static var activationDepth = 0

    /// Whether Swift's `async` main runs the main run loop, so that stopping it ends the process:
    /// true under `swift test`, false under Xcode, which runs tests from a synchronous main.
    static var isNeeded: Bool {
      get async {
        await performOnMainRunLoop { isMainRunLoopRunByAsyncMain }
      }
    }

    /// Starts watching the main run loop, if Swift's `async` main runs it. Call this before any test
    /// runs a nested event loop.
    static func start() async {
      await performOnMainRunLoop { startWatching() }
    }

    // NB: Inside a Swift task the backtrace only lists the task's own async frames, so this has to
    //     be read in a run loop callout to see what runs the run loop.
    private static var isMainRunLoopRunByAsyncMain: Bool {
      Thread.callStackSymbols.contains { $0.contains("swift_task_asyncMainDrainQueue") }
    }

    private static func startWatching() {
      guard !isStarted, isMainRunLoopRunByAsyncMain else { return }
      isStarted = true
      // NB: This runs in a callout of the run loop Swift's `async` main runs, before any test runs
      //     a nested one.
      activationDepth = 1
      let observer = CFRunLoopObserverCreateWithHandler(
        kCFAllocatorDefault,
        CFRunLoopActivity([.entry, .exit]).rawValue,
        true,
        // NB: Runs after every other observer of a run loop that exits, AppKit's autorelease pool
        //     included.
        CFIndex.max
      ) { _, activity in
        MainActor.assumeIsolated {
          observe(activity)
        }
      }
      CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
    }

    private static func observe(_ activity: CFRunLoopActivity) {
      activationDepth += activity == .entry ? 1 : -1
      guard activationDepth == 0 else { return }
      // NB: The run loop of Swift's `async` main is returning, and the process exits once it has.
      //     Swift Testing ends a run by calling `exit` itself, so only a stray stop gets here.
      //     Running the main run loop again from this callout keeps the tests going; Core
      //     Foundation never calls an observer that is still running, so nothing re-enters this.
      while true {
        CFRunLoopRun()
      }
    }

    /// Runs `body` in a callout of the main run loop rather than in a Swift task.
    private static func performOnMainRunLoop<Value: Sendable>(
      _ body: @escaping @MainActor @Sendable () -> Value
    ) async -> Value {
      await withCheckedContinuation { continuation in
        CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) {
          continuation.resume(returning: MainActor.assumeIsolated(body))
        }
        CFRunLoopWakeUp(CFRunLoopGetMain())
      }
    }
  }
#endif
