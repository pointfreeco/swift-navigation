#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import XCTest

  // NB: The presentation tests are synchronous XCTest methods on purpose. They wait by spinning
  //     the main run loop, which is what drives sheet and popover animations, window ordering, the
  //     main-queue re-runs of 'observe', and the modal loops that 'modal' runs. A modal loop blocks
  //     whatever spins the run loop until the loop ends, so anything a test does while a modal is
  //     up has to be scheduled with 'perform(after:_:)' before the modal starts.
  extension XCTestCase {
    /// Spins the main run loop until `condition` holds or `timeout` passes, and returns whether it
    /// holds.
    @MainActor
    func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) -> Bool {
      let deadline = Date(timeIntervalSinceNow: timeout)
      while !condition(), Date() < deadline {
        spinRunLoopOnce()
      }
      return condition()
    }

    /// Spins the main run loop for `duration`.
    @MainActor
    func spinRunLoop(for duration: TimeInterval) {
      let deadline = Date(timeIntervalSinceNow: duration)
      while Date() < deadline {
        spinRunLoopOnce()
      }
    }

    // NB: Each turn drains an autorelease pool of its own, so that an object the presentation code
    //     no longer holds is gone by the time a test looks for it.
    @MainActor
    private func spinRunLoopOnce() {
      autoreleasepool {
        _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
      }
    }

    /// Runs `work` on the main actor once `delay` has passed, from whichever loop is turning the
    /// main run loop then — a modal loop that blocks the test method included.
    @MainActor
    func perform(after delay: TimeInterval, _ work: @escaping @MainActor () -> Void) {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        MainActor.assumeIsolated {
          work()
        }
      }
    }

    /// Aborts every modal loop still running once `timeout` has passed, so that a loop that never
    /// stops fails its test instead of hanging the whole run.
    @MainActor
    func abortModalLoops(after timeout: TimeInterval) {
      let timer = Timer(fire: Date(timeIntervalSinceNow: timeout), interval: 0.2, repeats: true) {
        _ in
        MainActor.assumeIsolated {
          if NSApplication.shared.modalWindow != nil {
            NSApplication.shared.abortModal()
          }
        }
      }
      RunLoop.main.add(timer, forMode: .common)
      addTeardownBlock { @MainActor in
        timer.invalidate()
      }
    }

    /// A titled, closable window that is closed when the test ends.
    @MainActor
    func makeWindow(width: CGFloat = 240, height: CGFloat = 160) -> NSWindow {
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: width, height: height),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
      )
      window.isReleasedWhenClosed = false
      addTeardownBlock { @MainActor in
        window.close()
      }
      return window
    }

    /// A view controller whose view is a plain view of the given size.
    @MainActor
    func makeViewController(width: CGFloat = 200, height: CGFloat = 120) -> NSViewController {
      let viewController = NSViewController()
      viewController.view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
      return viewController
    }

    /// A window on screen whose content is a view controller, closed when the test ends.
    @MainActor
    func makeHost(width: CGFloat = 480, height: CGFloat = 320) -> PresentationHost {
      let viewController = makeViewController(width: width, height: height)
      let window = NSWindow(contentViewController: viewController)
      window.isReleasedWhenClosed = false
      window.orderFront(nil)
      addTeardownBlock { @MainActor in
        while let attachedSheet = window.attachedSheet {
          window.endSheet(attachedSheet)
        }
        window.close()
      }
      return PresentationHost(window: window, viewController: viewController)
    }

    /// Starts collecting the popovers shown from now until the test ends, and closes any that are
    /// still open then.
    @MainActor
    func recordShownPopovers() -> PopoverRecorder {
      let recorder = PopoverRecorder()
      addTeardownBlock { @MainActor in
        recorder.stopRecording()
        for popover in recorder.shownPopovers where popover.isShown {
          popover.close()
        }
      }
      return recorder
    }
  }

  /// A window on screen and the view controller that is its content.
  @MainActor
  struct PresentationHost {
    let window: NSWindow
    let viewController: NSViewController

    var view: NSView { viewController.view }
  }

  /// Collects the popovers that are shown while it records.
  @MainActor
  final class PopoverRecorder: NSObject {
    private(set) var shownPopovers: [NSPopover] = []

    override init() {
      super.init()
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(popoverWillShow(_:)),
        name: NSPopover.willShowNotification,
        object: nil
      )
    }

    func stopRecording() {
      NotificationCenter.default.removeObserver(self)
    }

    @objc private func popoverWillShow(_ notification: Notification) {
      guard let popover = notification.object as? NSPopover else { return }
      shownPopovers.append(popover)
    }
  }

  /// A value that work scheduled with `perform(after:_:)` sets, for the test to check once that
  /// work has run.
  @MainActor
  final class Recorded<Value> {
    var value: Value

    init(_ value: Value) {
      self.value = value
    }
  }
#endif
