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
          self.dismiss(
            animated: !transaction.uiKit.disablesAnimations
          ) {
            onDismiss?()
            self.present(child, animated: !transaction.uiKit.disablesAnimations)
          }
        } else {
          self.present(child, animated: !transaction.uiKit.disablesAnimations)
        }
      } dismiss: { child, transaction in
        child.dismiss(animated: !transaction.uiKit.disablesAnimations) {
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

    /// Pushes view controllers onto the receiver's stack using the given items as data sources,
    /// coordinating between them to avoid race conditions when switching destinations.
    ///
    /// Like SwiftUI's `navigationDestination(item:)` view modifier, but for UIKit, and handles
    /// switching between multiple destinations by using `setViewControllers` instead of separate
    /// dismiss and push operations.
    ///
    /// - Parameters:
    ///   - item1: A binding to an optional source of truth for the first view controller.
    ///   - content1: A closure that returns the first view controller to display.
    ///   - item2: A binding to an optional source of truth for the second view controller.
    ///   - content2: A closure that returns the second view controller to display.
    @_disfavoredOverload
    @discardableResult
    public func navigationDestination<Item1, Item2>(
      item1: UIBinding<Item1?>,
      content1: @escaping (UIBinding<Item1>) -> UIViewController,
      item2: UIBinding<Item2?>,
      content2: @escaping (UIBinding<Item2>) -> UIViewController
    ) -> ObserveToken {
      let key1 = UIBindingIdentifier(item1)
      let key2 = UIBindingIdentifier(item2)
      
      return observe { [weak self] transaction in
        guard let self else { return }
        guard
          let navigationController = self.navigationController ?? self as? UINavigationController
        else {
          reportIssue(
            """
            Can't present navigation item: "navigationController" is "nil".
            """
          )
          return
        }
        
        let presented1 = presentedByID[key1]
        let presented2 = presentedByID[key2]
        let unwrappedItem1 = UIBinding(item1)
        let unwrappedItem2 = UIBinding(item2)
        
        // Case 1: Switching from item1 to item2
        if presented1?.controller != nil, unwrappedItem1 == nil, let item = unwrappedItem2 {
          let childController = content2(item)
          let onDismiss = { [weak self] in
            if item2.wrappedValue != nil {
              item2.wrappedValue = nil
            }
          }
          childController._UIKitNavigation_onDismiss = onDismiss
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            childController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          
          self.presentedByID[key2] = Presented(childController, id: nil)
          self.presentedByID[key1] = nil
          
          var currentStack = navigationController.viewControllers
          if let lastVC = currentStack.last, lastVC !== self {
            currentStack[currentStack.count - 1] = childController
            navigationController.setViewControllers(
              currentStack, animated: !transaction.uiKit.disablesAnimations
            )
          } else {
            navigationController.pushViewController(
              childController, animated: !transaction.uiKit.disablesAnimations
            )
          }
          return
        }
        
        // Case 2: Switching from item2 to item1
        if presented2?.controller != nil, unwrappedItem2 == nil, let item = unwrappedItem1 {
          let childController = content1(item)
          let onDismiss = { [weak self] in
            if item1.wrappedValue != nil {
              item1.wrappedValue = nil
            }
          }
          childController._UIKitNavigation_onDismiss = onDismiss
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            childController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          
          self.presentedByID[key1] = Presented(childController, id: nil)
          self.presentedByID[key2] = nil
          
          var currentStack = navigationController.viewControllers
          if let lastVC = currentStack.last, lastVC !== self {
            currentStack[currentStack.count - 1] = childController
            navigationController.setViewControllers(
              currentStack, animated: !transaction.uiKit.disablesAnimations
            )
          } else {
            navigationController.pushViewController(
              childController, animated: !transaction.uiKit.disablesAnimations
            )
          }
          return
        }
        
        // Case 3: Normal push for item1
        if let item = unwrappedItem1, presented1 == nil {
          let childController = content1(item)
          let onDismiss = { [weak self] in
            if item1.wrappedValue != nil {
              item1.wrappedValue = nil
            }
          }
          childController._UIKitNavigation_onDismiss = onDismiss
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            childController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          
          self.presentedByID[key1] = Presented(childController, id: nil)
          navigationController.pushViewController(
            childController, animated: !transaction.uiKit.disablesAnimations
          )
          return
        }
        
        // Case 4: Normal push for item2
        if let item = unwrappedItem2, presented2 == nil {
          let childController = content2(item)
          let onDismiss = { [weak self] in
            if item2.wrappedValue != nil {
              item2.wrappedValue = nil
            }
          }
          childController._UIKitNavigation_onDismiss = onDismiss
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            childController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          
          self.presentedByID[key2] = Presented(childController, id: nil)
          navigationController.pushViewController(
            childController, animated: !transaction.uiKit.disablesAnimations
          )
          return
        }
        
        // Case 5: Normal dismiss for item1
        if unwrappedItem1 == nil, let presented = presented1, let controller = presented.controller {
          self.presentedByID[key1] = nil
          navigationController.popFromViewController(
            controller, animated: !transaction.uiKit.disablesAnimations
          )
          return
        }
        
        // Case 6: Normal dismiss for item2
        if unwrappedItem2 == nil, let presented = presented2, let controller = presented.controller {
          self.presentedByID[key2] = nil
          navigationController.popFromViewController(
            controller, animated: !transaction.uiKit.disablesAnimations
          )
          return
        }
      }
    }

    /// A type-erased navigation destination that can be stored in a collection.
    public struct NavigationDestinationItem {
      let key: UIBindingIdentifier
      let isPresented: () -> Bool
      let makeViewController: () -> UIViewController
      let clearBinding: () -> Void
      
      public init<Item>(
        item: UIBinding<Item?>,
        content: @escaping (UIBinding<Item>) -> UIViewController
      ) {
        self.key = UIBindingIdentifier(item)
        self.isPresented = { item.wrappedValue != nil }
        self.makeViewController = {
          guard let unwrapped = UIBinding(item) else {
            fatalError("Attempted to make view controller when item is nil")
          }
          return content(unwrapped)
        }
        self.clearBinding = { item.wrappedValue = nil }
      }
    }
    
    /// Pushes view controllers onto the receiver's stack using multiple items as data sources,
    /// coordinating between them to avoid race conditions when switching destinations.
    ///
    /// Like SwiftUI's `navigationDestination(item:)` view modifier, but for UIKit, and handles
    /// switching between multiple destinations by using `setViewControllers` instead of separate
    /// dismiss and push operations.
    ///
    /// - Parameter destinations: A dictionary mapping identifiers to navigation destination items.
    @_disfavoredOverload
    @discardableResult
    public func navigationDestinations(
      _ destinations: [UIBindingIdentifier: NavigationDestinationItem]
    ) -> ObserveToken {
      return observe { [weak self] transaction in
        guard let self else { return }
        guard
          let navigationController = self.navigationController ?? self as? UINavigationController
        else {
          reportIssue(
            """
            Can't present navigation item: "navigationController" is "nil".
            """
          )
          return
        }
        
        // Find which destination is currently presented (O(n) but only once)
        var currentlyPresentedKey: UIBindingIdentifier?
        for (key, _) in destinations {
          if presentedByID[key]?.controller != nil {
            currentlyPresentedKey = key
            break
          }
        }
        
        // Find which destination should be presented (O(n) but only once)
        var shouldPresentKey: UIBindingIdentifier?
        for (key, destination) in destinations {
          if destination.isPresented() {
            shouldPresentKey = key
            break
          }
        }
        
        // Case 1: Switching from one destination to another
        if let currentKey = currentlyPresentedKey,
           let newKey = shouldPresentKey,
           currentKey != newKey,
           let newDestination = destinations[newKey] {
          
          let childController = newDestination.makeViewController()
          let onDismiss = { [weak self] in
            if newDestination.isPresented() {
              newDestination.clearBinding()
            }
          }
          childController._UIKitNavigation_onDismiss = onDismiss
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            childController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          
          self.presentedByID[newKey] = Presented(childController, id: nil)
          self.presentedByID[currentKey] = nil
          
          var currentStack = navigationController.viewControllers
          if let lastVC = currentStack.last, lastVC !== self {
            currentStack[currentStack.count - 1] = childController
            navigationController.setViewControllers(
              currentStack, animated: !transaction.uiKit.disablesAnimations
            )
          } else {
            navigationController.pushViewController(
              childController, animated: !transaction.uiKit.disablesAnimations
            )
          }
          return
        }
        
        // Case 2: Normal push (no destination currently presented)
        if currentlyPresentedKey == nil,
           let newKey = shouldPresentKey,
           let newDestination = destinations[newKey] {
          
          let childController = newDestination.makeViewController()
          let onDismiss = { [weak self] in
            if newDestination.isPresented() {
              newDestination.clearBinding()
            }
          }
          childController._UIKitNavigation_onDismiss = onDismiss
          if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            childController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          
          self.presentedByID[newKey] = Presented(childController, id: nil)
          navigationController.pushViewController(
            childController, animated: !transaction.uiKit.disablesAnimations
          )
          return
        }
        
        // Case 3: Normal dismiss (destination presented but should not be)
        if let currentKey = currentlyPresentedKey,
           shouldPresentKey == nil {
          
          if let presented = presentedByID[currentKey],
             let controller = presented.controller {
            self.presentedByID[currentKey] = nil
            navigationController.popFromViewController(
              controller, animated: !transaction.uiKit.disablesAnimations
            )
          }
          return
        }
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
      dismiss:
        @escaping (
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
      dismiss:
        @escaping (
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
      present:
        @escaping (
          _ child: UIViewController,
          _ transaction: UITransaction
        ) -> Void,
      dismiss:
        @escaping (
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
      present:
        @escaping (
          _ child: UIViewController,
          _ transaction: UITransaction
        ) -> Void,
      dismiss:
        @escaping (
          _ child: UIViewController,
          _ transaction: UITransaction
        ) -> Void
    ) -> ObserveToken {
      let key = UIBindingIdentifier(item)
      var inFlightController: UIViewController?
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
          let onDismiss = {
            [
              weak self,
              presentationID = id(unwrappedItem.wrappedValue)
            ] in
            if let wrappedValue = item.wrappedValue, presentationID == id(wrappedValue) {
              inFlightController = self?.presentedByID[key]?.controller
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
            var controllerToDismiss: UIViewController? = nil
            if inFlightController != nil {
              controllerToDismiss = inFlightController
              inFlightController = nil
            } else if controller.presentedViewController != nil {
              controllerToDismiss = self
            } else {
              controllerToDismiss = controller
            }
            if let controllerToDismiss {
              dismiss(controllerToDismiss, transaction)
            }
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
