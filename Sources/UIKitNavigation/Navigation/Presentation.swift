#if canImport(UIKit) && !os(watchOS)
  import IssueReporting
  @_spi(Internals) import SwiftNavigation
  import UIKit
  @_implementationOnly import UIKitNavigationShim

  extension UIViewController {
    /// Presents a view controller modally when a binding to a Boolean value you provide is true.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the view
    ///     controller.
    ///   - onDismiss: The closure to execute when dismissing the view controller.
    ///   - content: A closure that returns the view controller to display over the current view
    ///     controller's content.
    @discardableResult
    public func present(
      isPresented: UIBinding<Bool>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> UIViewController
    ) -> ObserveToken {
      present(item: isPresented.toOptionalUnit, onDismiss: onDismiss) { _ in content() }
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user. If `item`'s
    ///     identity changes, the view controller is dismissed and replaced with a new one using the
    ///     same process.
    ///   - onDismiss: The closure to execute when dismissing the view controller.
    ///   - content: A closure that returns the view controller to display over the current view
    ///     controller's content.
    @discardableResult
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> UIViewController
    ) -> ObserveToken {
      present(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user. If `item`'s
    ///     identity changes, the view controller is dismissed and replaced with a new one using the
    ///     same process.
    ///   - onDismiss: The closure to execute when dismissing the view controller.
    ///   - content: A closure that returns the view controller to display over the current view
    ///     controller's content.
    @_disfavoredOverload
    @discardableResult
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> UIViewController
    ) -> ObserveToken {
      present(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user. If `item`'s
    ///     identity changes, the view controller is dismissed and replaced with a new one using the
    ///     same process.
    ///   - id: The key path to the provided item's identifier.
    ///   - onDismiss: The closure to execute when dismissing the view controller.
    ///   - content: A closure that returns the view controller to display over the current view
    ///     controller's content.
    @discardableResult
    public func present<Item, ID: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, ID>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> UIViewController
    ) -> ObserveToken {
      present(item: item, id: id, onDismiss: onDismiss) {
        content($0.wrappedValue)
      }
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user. If `item`'s
    ///     identity changes, the view controller is dismissed and replaced with a new one using the
    ///     same process.
    ///   - id: The key path to the provided item's identifier.
    ///   - onDismiss: The closure to execute when dismissing the view controller.
    ///   - content: A closure that returns the view controller to display over the current view
    ///     controller's content.
    @_disfavoredOverload
    @discardableResult
    public func present<Item, ID: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, ID>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> UIViewController
    ) -> ObserveToken {
      destination(item: item, id: id) { $item in
        content($item)
      } present: { [weak self] child, transaction in
        guard let self else { return }
        if presentedViewController != nil {
          self.dismiss(animated: !transaction.uiKit.disablesAnimations) {
            onDismiss?()
            self.present(child, animated: !transaction.uiKit.disablesAnimations)
          }
        } else {
          self.present(child, animated: !transaction.uiKit.disablesAnimations)
        }
      } dismiss: { [weak self] _, transaction in
        self?.dismiss(animated: !transaction.uiKit.disablesAnimations) {
          onDismiss?()
        }
      }
    }

    /// Pushes a view controller onto the receiver's stack when a binding to a Boolean value you
    /// provide is true.
    ///
    /// Like SwiftUI's `navigationDestination(isPresented:)` view modifier, but for UIKit.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to push the view
    ///     controller.
    ///   - content: A closure that returns the view controller to display onto the receiver's
    ///     stack.
    @discardableResult
    public func navigationDestination(
      isPresented: UIBinding<Bool>,
      content: @escaping () -> UIViewController
    ) -> ObserveToken {
      navigationDestination(item: isPresented.toOptionalUnit) { _ in content() }
    }

    /// Pushes a view controller onto the receiver's stack using the given item as a data source for
    /// its content.
    ///
    /// Like SwiftUI's `navigationDestination(item:)` view modifier, but for UIKit.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user.
    ///   - content: A closure that returns the view controller to display onto the receiver's
    ///     stack.
    @discardableResult
    public func navigationDestination<Item>(
      item: UIBinding<Item?>,
      content: @escaping (Item) -> UIViewController
    ) -> ObserveToken {
      navigationDestination(item: item) {
        content($0.wrappedValue)
      }
    }

    /// Pushes a view controller onto the receiver's stack using the given item as a data source for
    /// its content.
    ///
    /// Like SwiftUI's `navigationDestination(item:)` view modifier, but for UIKit.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user.
    ///   - content: A closure that returns the view controller to display onto the receiver's
    ///     stack.
    @_disfavoredOverload
    @discardableResult
    public func navigationDestination<Item>(
      item: UIBinding<Item?>,
      content: @escaping (UIBinding<Item>) -> UIViewController
    ) -> ObserveToken {
      destination(item: item) { $item in
        content($item)
      } present: { [weak self] child, transaction in
        guard
          let navigationController = self?.navigationController ?? self as? UINavigationController
        else {
          reportIssue(
            """
            Can't present navigation item: "navigationController" is "nil".
            """
          )
          return
        }
        navigationController.pushViewController(
          child, animated: !transaction.uiKit.disablesAnimations
        )
      } dismiss: { [weak self] child, transaction in
        guard
          let navigationController = self?.navigationController ?? self as? UINavigationController
        else {
          reportIssue(
            """
            Can't dismiss navigation item: "navigationController" is "nil".
            """
          )
          return
        }
        navigationController.popFromViewController(
          child, animated: !transaction.uiKit.disablesAnimations
        )
      }
    }

    /// Presents a view controller when a binding to a Boolean value you provide is true.
    ///
    /// This helper powers ``present(isPresented:onDismiss:content:)`` and
    /// ``UIKit/UINavigationController/pushViewController(isPresented:content:)`` and can be used to
    /// define custom transitions.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the view
    ///     controller.
    ///   - content: A closure that returns the view controller to display.
    ///   - present: The closure to execute when presenting the view controller.
    ///   - dismiss: The closure to execute when dismissing the view controller.
    @discardableResult
    public func destination(
      isPresented: UIBinding<Bool>,
      content: @escaping () -> UIViewController,
      present: @escaping (UIViewController, UITransaction) -> Void,
      dismiss: @escaping (
        _ child: UIViewController,
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

    /// Presents a view controller using the given item as a data source for its content.
    ///
    /// This helper powers ``navigationDestination(item:content:)-1gks3`` and can be used to define
    /// custom transitions.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user.
    ///   - content: A closure that returns the view controller to display.
    ///   - present: The closure to execute when presenting the view controller.
    ///   - dismiss: The closure to execute when dismissing the view controller.
    @discardableResult
    public func destination<Item>(
      item: UIBinding<Item?>,
      content: @escaping (UIBinding<Item>) -> UIViewController,
      present: @escaping (UIViewController, UITransaction) -> Void,
      dismiss: @escaping (
        _ child: UIViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      destination(
        item: item,
        id: { _ in nil },
        content: content,
        present: present,
        dismiss: dismiss
      )
    }

    /// Presents a view controller using the given item as a data source for its content.
    ///
    /// This helper powers ``present(item:onDismiss:content:)-4m7m3`` and can be used to define
    /// custom transitions.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user. If `item`'s
    ///     identity changes, the view controller is dismissed and replaced with a new one using the
    ///     same process.
    ///   - id: The key path to the provided item's identifier.
    ///   - content: A closure that returns the view controller to display.
    ///   - present: The closure to execute when presenting the view controller.
    ///   - dismiss: The closure to execute when dismissing the view controller.
    @discardableResult
    public func destination<Item, ID: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, ID>,
      content: @escaping (UIBinding<Item>) -> UIViewController,
      present: @escaping (
        _ child: UIViewController,
        _ transaction: UITransaction
      ) -> Void,
      dismiss: @escaping (
        _ child: UIViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      destination(
        item: item,
        id: { $0[keyPath: id] },
        content: content,
        present: present,
        dismiss: dismiss
      )
    }

    private func destination<Item>(
      item: UIBinding<Item?>,
      id: @escaping (Item) -> AnyHashable?,
      content: @escaping (UIBinding<Item>) -> UIViewController,
      present: @escaping (
        _ child: UIViewController,
        _ transaction: UITransaction
      ) -> Void,
      dismiss: @escaping (
        _ child: UIViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      let key = UIBindingIdentifier(item)
      return observe { [weak self] transaction in
        guard let self else { return }
        if let unwrappedItem = UIBinding(item) {
          if let presented = presentedByID[key] {
            guard let presentationID = presented.presentationID,
              presentationID != id(unwrappedItem.wrappedValue)
            else {
              return
            }
          }
          let childController = content(unwrappedItem)
          let onDismiss = { [presentationID = id(unwrappedItem.wrappedValue)] in
            if let wrappedValue = item.wrappedValue,
              presentationID == id(wrappedValue)
            {
              item.wrappedValue = nil
            }
          }
          childController._UIKitNavigation_onDismiss = onDismiss
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            childController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          self.presentedByID[key] = Presented(childController, id: id(unwrappedItem.wrappedValue))
          let work = {
            withUITransaction(transaction) {
              present(childController, transaction)
            }
          }
          if _UIKitNavigation_hasViewAppeared {
            work()
          } else {
            _UIKitNavigation_onViewAppear.append(work)
          }
        } else if let presented = presentedByID[key] {
          if let controller = presented.controller {
            dismiss(controller, transaction)
          }
          self.presentedByID[key] = nil
        }
      }
    }

    fileprivate var presentedByID: [UIBindingIdentifier: Presented] {
      get {
        (objc_getAssociatedObject(self, Self.presentedKey)
          as? [UIBindingIdentifier: Presented])
          ?? [:]
      }
      set {
        objc_setAssociatedObject(
          self, Self.presentedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
      }
    }

    private static let presentedKey = malloc(1)!
  }

  extension UINavigationController {
    @available(
      *, deprecated,
      message: """
        Use 'self.navigationDestination(isPresented:)' instead of 'self.navigationController?.pushViewController(isPresented:)'.
        """
    )
    @discardableResult
    public func pushViewController(
      isPresented: UIBinding<Bool>,
      content: @escaping () -> UIViewController
    ) -> ObserveToken {
      navigationDestination(isPresented: isPresented, content: content)
    }

    @available(
      *, deprecated,
      message: """
        Use 'self.navigationDestination(item:)' instead of 'self.navigationController?.pushViewController(item:)'.
        """
    )
    @discardableResult
    public func pushViewController<Item>(
      item: UIBinding<Item?>,
      content: @escaping (Item) -> UIViewController
    ) -> ObserveToken {
      navigationDestination(item: item, content: content)
    }

    @available(
      *, deprecated,
      message: """
        Use 'self.navigationDestination(item:)' instead of 'self.navigationController?.pushViewController(item:)'.
        """
    )
    @_disfavoredOverload
    @discardableResult
    public func pushViewController<Item>(
      item: UIBinding<Item?>,
      content: @escaping (UIBinding<Item>) -> UIViewController
    ) -> ObserveToken {
      navigationDestination(item: item, content: content)
    }
  }

  @MainActor
  private class Presented {
    weak var controller: UIViewController?
    let presentationID: AnyHashable?
    deinit {
      // NB: This can only be assumed because it is held in a UIViewController and is guaranteed to
      //     deinit alongside it on the main thread. If we use this other places we should force it
      //     to be a UIViewController as well, to ensure this functionality.
      MainActor._assumeIsolated {
        guard let controller, controller.parent == nil else { return }
        controller.dismiss(animated: false)
      }
    }
    init(_ controller: UIViewController, id presentationID: AnyHashable? = nil) {
      self.controller = controller
      self.presentationID = presentationID
    }
  }
#endif
