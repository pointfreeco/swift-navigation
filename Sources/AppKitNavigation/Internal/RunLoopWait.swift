#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  import AppKit

  /// Waits for something on screen to change — a window to come on screen, a view to get into a
  /// window, a sheet to finish leaving the screen — by checking each time the main run loop is
  /// about to wait.
  ///
  /// Notifications are not reliable for this. A window brought on screen in a process that is not
  /// the active app — a test runner, for one — posts no occlusion, key or main window notification
  /// at all, a view has none for getting into a window, and a sheet's completion handler runs
  /// before the sheet has left the screen. The check costs a closure call per turn of the run
  /// loop, and only while something is waiting.
  @MainActor
  enum RunLoopWait {
    /// Calls `body` once `condition` holds — right away when it already does — and returns a
    /// closure that cancels the wait.
    static func until(
      _ condition: @escaping @MainActor () -> Bool,
      then body: @escaping @MainActor () -> Void
    ) -> @MainActor () -> Void {
      if condition() {
        body()
        return {}
      }
      // NB: In the common modes, so that the wait goes on inside modal loops and while the mouse
      //     is tracking.
      nonisolated(unsafe) let observer = CFRunLoopObserverCreateWithHandler(
        nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 0
      ) { observer, _ in
        MainActor._assumeIsolated {
          guard condition() else { return }
          CFRunLoopObserverInvalidate(observer)
          body()
        }
      }
      CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
      return {
        CFRunLoopObserverInvalidate(observer)
      }
    }
  }

#endif
