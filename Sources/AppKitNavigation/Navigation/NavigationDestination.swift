#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  public import AppKit
  import AppKitPlus
  public import SwiftNavigation
  import AppKitNavigationShim

  extension NSViewController {
    /// Pushes a view controller onto the enclosing navigation controller while a binding to a
    /// Boolean value you provide is true.
    ///
    /// Like SwiftUI's `navigationDestination(isPresented:)`, for AppKitPlus's
    /// `NSNavigationController`. Setting the binding to `false` pops the view controller, along
    /// with anything pushed above it. When the user goes back past it — with the back button, ⌘↑
    /// or a swipe — or it dismisses itself with `traitCollection.dismiss()`, the binding is set to
    /// `false`. The view controller is pushed once this view controller's view has appeared.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to push the view
    ///     controller.
    ///   - onDismiss: The closure to execute once the view controller has been popped and has left
    ///     the screen.
    ///   - content: A closure that returns the view controller to push.
    /// - Returns: A token that stops following the binding once cancelled.
    #if !Perception
      @available(macOS 14, *)
    #endif
    @discardableResult
    public func navigationDestination(
      isPresented: UIBinding<Bool>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> NSViewController
    ) -> ObserveToken {
      navigationDestination(item: isPresented.toOptionalUnit, onDismiss: onDismiss) { _ in
        content()
      }
    }

    /// Pushes a view controller onto the enclosing navigation controller while a binding to an
    /// optional item holds a value.
    ///
    /// The view controller is pushed and popped as with
    /// ``navigationDestination(isPresented:onDismiss:content:)``. If the item's identity changes,
    /// the view controller is popped, and once it has left the screen, one for the new item is
    /// pushed.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, the value is passed to `content`. When the user goes back past the view
    ///     controller, the binding is set to `nil`.
    ///   - onDismiss: The closure to execute once the view controller has been popped and has left
    ///     the screen.
    ///   - content: A closure that returns the view controller to push for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    #if !Perception
      @available(macOS 14, *)
    #endif
    @discardableResult
    public func navigationDestination<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      navigationDestination(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    /// Pushes a view controller onto the enclosing navigation controller while a binding to an
    /// optional item holds a value, passing the content a binding to the item.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user goes back past the
    ///     view controller, the binding is set to `nil`.
    ///   - onDismiss: The closure to execute once the view controller has been popped and has left
    ///     the screen.
    ///   - content: A closure that returns the view controller to push for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    #if !Perception
      @available(macOS 14, *)
    #endif
    @_disfavoredOverload
    @discardableResult
    public func navigationDestination<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      navigationDestination(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    /// Pushes a view controller onto the enclosing navigation controller while a binding to an
    /// optional item holds a value, telling items apart by the identifier at a key path.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, the value is passed to `content`. When the user goes back past the view
    ///     controller, the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     popped, and once it has left the screen, one for the new item is pushed.
    ///   - onDismiss: The closure to execute once the view controller has been popped and has left
    ///     the screen.
    ///   - content: A closure that returns the view controller to push for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    #if !Perception
      @available(macOS 14, *)
    #endif
    @discardableResult
    public func navigationDestination<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      navigationDestination(item: item, id: id, onDismiss: onDismiss) {
        content($0.wrappedValue)
      }
    }

    /// Pushes a view controller onto the enclosing navigation controller while a binding to an
    /// optional item holds a value, telling items apart by the identifier at a key path and
    /// passing the content a binding to the item.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user goes back past the
    ///     view controller, the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     popped, and once it has left the screen, one for the new item is pushed.
    ///   - onDismiss: The closure to execute once the view controller has been popped and has left
    ///     the screen.
    ///   - content: A closure that returns the view controller to push for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    #if !Perception
      @available(macOS 14, *)
    #endif
    @_disfavoredOverload
    @discardableResult
    public func navigationDestination<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        NavigationPushStyle(presenter: self),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss,
        content: content
      )
    }
  }

  /// Shows content by pushing it onto the navigation controller the presenter is in.
  @MainActor
  private struct NavigationPushStyle: PresentationStyle {
    weak var presenter: NSViewController?

    func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
      guard let presenter, !presenter._AppKitNavigation_hasViewAppeared else {
        body()
        return {}
      }
      let wait = PushWait()
      presenter._AppKitNavigation_onViewAppear.append {
        MainActor._assumeIsolated {
          guard !wait.isCancelled else { return }
          body()
        }
      }
      return {
        wait.isCancelled = true
      }
    }

    func begin(
      _ child: NSViewController,
      transaction: UITransaction,
      didEnd: @escaping @MainActor () -> Void
    ) {
      guard
        let presenter,
        let navigationController = presenter.navigationController
          ?? presenter as? NSNavigationController
      else {
        reportIssue(
          """
          Can't push a navigation destination: "navigationController" is "nil".

          'navigationDestination' must be called on a view controller in an \
          'NSNavigationController'.
          """
        )
        didEnd()
        return
      }
      let record = PushRecord(navigationController: navigationController)
      child.appKitNavigationPushRecord = record
      navigationController.pushViewController(
        child, animated: !transaction.appKit.disablesAnimations
      )
      // NB: AppKitPlus never sends 'didMove(toParent: nil)' when it pops a view controller, so a
      //     pushed one counts as gone once it has been on the stack, has left its navigation
      //     controller, and its view has left the window. A push that waits for a running
      //     transition leaves the view controller off the stack for a while.
      _ = RunLoopWait.until(
        { [weak child] in
          guard let child else { return true }
          if child.parent != nil {
            record.hasBeenPushed = true
          }
          return record.hasBeenPushed && child.parent == nil
            && (!child.isViewLoaded || child.view.window == nil)
        },
        then: didEnd
      )
    }

    func end(_ child: NSViewController, transaction: UITransaction) {
      guard let navigationController = child.appKitNavigationPushRecord?.navigationController
      else { return }
      let animated = !transaction.appKit.disablesAnimations
      // NB: A push that is still waiting for a running transition is popped once it lands.
      _ = RunLoopWait.until({ [weak child] in child?.parent != nil || child == nil }) {
        [weak child, weak navigationController] in
        guard let child, let navigationController else { return }
        navigationController.popFromViewController(child, animated: animated)
      }
    }
  }

  /// Where a view controller was pushed, and whether it has reached the stack yet.
  @MainActor
  private final class PushRecord {
    weak var navigationController: NSNavigationController?
    var hasBeenPushed = false

    init(navigationController: NSNavigationController) {
      self.navigationController = navigationController
    }
  }

  /// A wait that can be called off after it has been scheduled.
  @MainActor
  private final class PushWait {
    var isCancelled = false
  }

  extension NSViewController {
    fileprivate var appKitNavigationPushRecord: PushRecord? {
      get {
        objc_getAssociatedObject(self, pushRecordKey) as? PushRecord
      }
      set {
        objc_setAssociatedObject(self, pushRecordKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }

  @MainActor
  private let pushRecordKey = malloc(1)!
#endif
