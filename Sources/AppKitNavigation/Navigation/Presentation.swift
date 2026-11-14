#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  public import AppKit
  import AppKitNavigationShim

  extension NSViewController {
    /// How a view controller presents another one.
    public enum TransitionStyle {
      /// Attached to the presenting view controller's window as a sheet.
      case sheet
      /// In a window of its own, run modally.
      case modalWindow
      /// In a popover pointing at a rectangle in a view.
      ///
      /// - Parameters:
      ///   - rect: The rectangle, in `view`'s coordinates, that the popover points at.
      ///   - view: The view the popover is anchored to.
      ///   - preferredEdge: The edge of `rect` the popover prefers to show from.
      ///   - behavior: Whether the popover closes when the user interacts with something else.
      case popover(rect: NSRect, view: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)
      /// By an animator of your own.
      case custom(any NSViewControllerPresentationAnimator)
    }

    /// Presents a view controller while a binding to a Boolean value you provide is true.
    ///
    /// Like SwiftUI's `sheet` and `popover` view modifiers, but for AppKit. Setting the binding to
    /// `false` dismisses the view controller. When the user dismisses it — a Cancel button wired to
    /// `dismissController(_:)`, a transient popover closing — the binding is set to `false`. The
    /// view controller is presented once this view controller's view has appeared.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the view
    ///     controller.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present.
    /// - Returns: A token that stops following the binding once cancelled. A view controller that
    ///   is presented then stays until the user dismisses it.
    @discardableResult
    public func present(
      isPresented: UIBinding<Bool>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> NSViewController
    ) -> ObserveToken {
      present(item: isPresented.toOptionalUnit, style: style, onDismiss: onDismiss) { _ in
        content()
      }
    }

    /// Presents a view controller while a binding to an optional item holds a value.
    ///
    /// The view controller is presented as with
    /// ``present(isPresented:style:onDismiss:content:)``. If the item's identity changes, the view
    /// controller is dismissed, and once it has left the screen, one for the new item is
    /// presented.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, the value is passed to `content`. When the user dismisses the view controller,
    ///     the binding is set to `nil`.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller while a binding to an optional item holds a value, passing the
    /// content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller while a binding to an optional item holds a value, telling items
    /// apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, the value is passed to `content`. When the user dismisses the view controller,
    ///     the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     dismissed, and once it has left the screen, one for the new item is presented.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func present<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      present(item: item, id: id, style: style, onDismiss: onDismiss) {
        content($0.wrappedValue)
      }
    }

    /// Presents a view controller while a binding to an optional item holds a value, telling items
    /// apart by the identifier at a key path and passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     dismissed, and once it has left the screen, one for the new item is presented.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func present<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        ViewControllerPresentationStyle(presenter: self, transition: .style(style)),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss,
        content: content
      )
    }

    /// Presents a view controller in a way of your own while a binding to a Boolean value you
    /// provide is true.
    ///
    /// This helper powers ``present(isPresented:style:onDismiss:content:)``, and can define custom
    /// transitions. A view controller dismissed through `dismiss(_:)` counts as having left the
    /// screen once its view has disappeared. One that never went through AppKit's presentation,
    /// such as a child added with `addChild(_:)`, counts as having left the screen as soon as
    /// `dismiss` returns.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the view
    ///     controller.
    ///   - content: A closure that returns the view controller to present.
    ///   - present: The closure to execute to present the view controller.
    ///   - dismiss: The closure to execute to dismiss the view controller.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func destination(
      isPresented: UIBinding<Bool>,
      content: @escaping () -> NSViewController,
      present: @escaping (NSViewController, UITransaction) -> Void,
      dismiss: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      destination(
        item: isPresented.toOptionalUnit,
        content: { _ in content() },
        present: present,
        dismiss: dismiss
      )
    }

    /// Presents a view controller in a way of your own while a binding to an optional item holds a
    /// value.
    ///
    /// The view controller stays the same while the binding holds any value, whatever its
    /// identity. To replace it when the item's identity changes, use
    /// ``destination(item:id:content:present:dismiss:)``.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - content: A closure that returns the view controller to present.
    ///   - present: The closure to execute to present the view controller.
    ///   - dismiss: The closure to execute to dismiss the view controller.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func destination<Item>(
      item: UIBinding<Item?>,
      content: @escaping (UIBinding<Item>) -> NSViewController,
      present: @escaping (NSViewController, UITransaction) -> Void,
      dismiss: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      bindPresentation(
        ViewControllerPresentationStyle(
          presenter: self, transition: .custom(present: present, dismiss: dismiss)
        ),
        item: item,
        id: { _ in nil },
        onDismiss: nil,
        content: content
      )
    }

    /// Presents a view controller in a way of your own while a binding to an optional item holds a
    /// value, telling items apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     dismissed, and once it has left the screen, one for the new item is presented.
    ///   - content: A closure that returns the view controller to present.
    ///   - present: The closure to execute to present the view controller.
    ///   - dismiss: The closure to execute to dismiss the view controller.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func destination<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      content: @escaping (UIBinding<Item>) -> NSViewController,
      present: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void,
      dismiss: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      bindPresentation(
        ViewControllerPresentationStyle(
          presenter: self, transition: .custom(present: present, dismiss: dismiss)
        ),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: nil,
        content: content
      )
    }

    fileprivate func present(_ viewController: NSViewController, as style: TransitionStyle) {
      switch style {
      case .sheet:
        presentAsSheet(viewController)
      case .modalWindow:
        presentAsModalWindow(viewController)
      case let .popover(rect, view, preferredEdge, behavior):
        present(
          viewController,
          asPopoverRelativeTo: rect,
          of: view,
          preferredEdge: preferredEdge,
          behavior: behavior
        )
      case let .custom(animator):
        present(viewController, animator: animator)
      }
    }
  }

  /// Presents a view controller from another one, through AppKit's view controller presentation or
  /// in a way of the caller's own.
  @MainActor
  private struct ViewControllerPresentationStyle: PresentationStyle {
    enum Transition {
      case style(NSViewController.TransitionStyle)
      case custom(
        present: (NSViewController, UITransaction) -> Void,
        dismiss: (NSViewController, UITransaction) -> Void
      )
    }

    weak var presenter: NSViewController?
    let transition: Transition

    func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
      guard let presenter, !presenter._AppKitNavigation_hasViewAppeared else {
        body()
        return {}
      }
      let wait = CancellableWait()
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
      guard let presenter else {
        didEnd()
        return
      }
      // NB: The user dismisses a presented view controller without going through the binding — a
      //     Cancel button wired to 'dismissController:', a transient popover closing — so the shim
      //     reports the dismissal, once the view controller's view has disappeared. It counts as
      //     ended once the window that showed it is off screen too.
      child._AppKitNavigation_onDismiss = { [weak child] in
        MainActor._assumeIsolated {
          _ = RunLoopWait.until({ child?.view.window?.isVisible != true }, then: didEnd)
        }
      }
      switch transition {
      case let .style(style):
        presenter.present(child, as: style)
      case let .custom(present, _):
        withUITransaction(transaction) {
          present(child, transaction)
        }
      }
    }

    func end(_ child: NSViewController, transaction: UITransaction) {
      switch transition {
      case .style:
        // NB: Only through this weak reference: 'presentingViewController' is not one, and is not
        //     safe to read while the presenter is being deallocated.
        if let presenter, presenter.presentedViewControllers?.contains(child) == true {
          presenter.dismiss(child)
          return
        }
      case let .custom(_, dismiss):
        withUITransaction(transaction) {
          dismiss(child, transaction)
        }
        if presenter?.presentedViewControllers?.contains(child) == true {
          return
        }
      }
      // NB: Not presented through AppKit, or no longer, so no dismissal will be reported.
      let reportDismissal = child._AppKitNavigation_onDismiss
      child._AppKitNavigation_onDismiss = nil
      reportDismissal?()
    }
  }

  /// A wait that can be called off after it has been scheduled.
  @MainActor
  private final class CancellableWait {
    var isCancelled = false
  }
#endif
