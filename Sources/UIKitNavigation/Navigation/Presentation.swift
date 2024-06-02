#if canImport(UIKit)
  @_spi(Internals) import SwiftNavigation
  import UIKit

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
    public func present(
      isPresented: UIBinding<Bool>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> UIViewController
    ) {
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
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> UIViewController
    ) {
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
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> UIViewController
    ) {
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
    public func present<Item, ID: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, ID>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> UIViewController
    ) {
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
    public func present<Item, ID: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, ID>,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> UIViewController
    ) {
      destination(item: item, id: id) { $item in
        content($item)
      } present: { [weak self] oldController, newController, transaction in
        if let oldController {
          oldController.dismiss(animated: !transaction.disablesAnimations) {
            onDismiss?()
            self?.present(newController, animated: !transaction.disablesAnimations)
          }
        } else {
          self?.present(newController, animated: !transaction.disablesAnimations)
        }
      } dismiss: { controller, transaction in
        controller.dismiss(animated: !transaction.disablesAnimations) {
          onDismiss?()
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
    public func destination(
      isPresented: UIBinding<Bool>,
      content: @escaping () -> UIViewController,
      present: @escaping (UIViewController, UITransaction) -> Void,
      dismiss: @escaping (UIViewController, UITransaction) -> Void
    ) {
      destination(
        item: isPresented.toOptionalUnit,
        content: { _ in content() },
        present: present,
        dismiss: dismiss
      )
    }

    /// Presents a view controller using the given item as a data source for its content.
    ///
    /// This helper powers ``UIKit/UINavigationController/pushViewController(item:content:)-4u68r)``
    /// and can be used to define custom transitions.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. When `item` is
    ///     non-`nil`, the item's content is passed to the `content` closure. You display this
    ///     content in a view controller that you create that is displayed to the user.
    ///   - content: A closure that returns the view controller to display.
    ///   - present: The closure to execute when presenting the view controller.
    ///   - dismiss: The closure to execute when dismissing the view controller.
    public func destination<Item>(
      item: UIBinding<Item?>,
      content: @escaping (UIBinding<Item>) -> UIViewController,
      present: @escaping (UIViewController, UITransaction) -> Void,
      dismiss: @escaping (UIViewController, UITransaction) -> Void
    ) {
      destination(
        item: item,
        id: { _ in nil },
        content: content,
        present: { present($1, $2) },
        dismiss: dismiss
      )
    }

    /// Presents a view controller using the given item as a data source for its content.
    ///
    /// This helper powers ``present(item:onDismiss:content:)-1zfb1`` and can be used to define
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
    public func destination<Item, ID: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, ID>,
      content: @escaping (UIBinding<Item>) -> UIViewController,
      present: @escaping (
        _ oldValue: UIViewController?, _ newValue: UIViewController, _ transaction: UITransaction
      ) -> Void,
      dismiss: @escaping (UIViewController, UITransaction) -> Void
    ) {
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
        _ oldValue: UIViewController?, _ newValue: UIViewController, _ transaction: UITransaction
      ) -> Void,
      dismiss: @escaping (UIViewController, UITransaction) -> Void
    ) {
      _ = Self.installSwizzles
      bindings.insert(item)
      let item = UIBinding(weak: item)
      observe { [weak self] transaction in
        guard let self else { return }
        if let unwrappedItem = UIBinding(item) {
          var oldController: UIViewController?
          if let presented = presented[item] {
            if let presentationID = presented.presentationID,
              presentationID != id(unwrappedItem.wrappedValue)
            {
              oldController = presented.controller
            } else {
              return
            }
          }
          let newController = content(unwrappedItem)
          let onDismiss = { [presentationID = id(unwrappedItem.wrappedValue)] in
            if presentationID == item.wrappedValue.flatMap(id) {
              item.wrappedValue = nil
            }
          }
          newController.onDismiss = onDismiss
          if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
            newController.traitOverrides.dismiss = UIDismissAction { _ in
              onDismiss()
            }
          }
          self.presented[item] = Presented(newController, id: id(unwrappedItem.wrappedValue))
          let work = {
            withUITransaction(transaction) {
              present(oldController, newController, transaction)
            }
          }
          if hasViewAppeared {
            DispatchQueue.main.async { work() }
          } else {
            onViewAppear.append(work)
          }
        } else if let presented = presented[item] {
          if let controller = presented.controller {
            dismiss(controller, transaction)
          }
          self.presented[item] = nil
        }
      }
    }

    fileprivate var bindings: Set<AnyHashable> {
      get {
        objc_getAssociatedObject(self, bindingsKey) as? Set<AnyHashable> ?? []
      }
      set {
        objc_setAssociatedObject(self, bindingsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }

    fileprivate var hasViewAppeared: Bool {
      get {
        objc_getAssociatedObject(self, hasViewAppearedKey) as? Bool ?? false
      }
      set {
        objc_setAssociatedObject(self, hasViewAppearedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }

    fileprivate var onViewAppear: [() -> Void] {
      get {
        objc_getAssociatedObject(self, onViewAppearKey) as? [() -> Void] ?? []
      }
      set {
        objc_setAssociatedObject(
          self, onViewAppearKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
      }
    }

    fileprivate var onDismiss: (() -> Void)? {
      get {
        objc_getAssociatedObject(self, onDismissKey) as? () -> Void
      }
      set {
        objc_setAssociatedObject(self, onDismissKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }

    fileprivate var presented: [AnyHashable: Presented] {
      get {
        (objc_getAssociatedObject(self, presentedKey)
          as? [AnyHashable: Presented])
          ?? [:]
      }
      set {
        objc_setAssociatedObject(self, presentedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }

  private let bindingsKey = malloc(1)!
  private let hasViewAppearedKey = malloc(1)!
  private let onDismissKey: UnsafeMutableRawPointer = malloc(1)!
  private let onViewAppearKey: UnsafeMutableRawPointer = malloc(1)!
  private let presentedKey = malloc(1)!

  extension UINavigationController {
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
    public func pushViewController(
      isPresented: UIBinding<Bool>,
      content: @escaping () -> UIViewController
    ) {
      pushViewController(item: isPresented.toOptionalUnit) { _ in content() }
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
    ///   - content: A closure that returns the view controller to display onto the receiver's stack.
    public func pushViewController<Item>(
      item: UIBinding<Item?>,
      content: @escaping (Item) -> UIViewController
    ) {
      pushViewController(item: item) {
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
    ///   - content: A closure that returns the view controller to display onto the receiver's stack.
    @_disfavoredOverload
    public func pushViewController<Item>(
      item: UIBinding<Item?>,
      content: @escaping (UIBinding<Item>) -> UIViewController
    ) {
      destination(item: item) { $item in
        content($item)
      } present: { [weak self] controller, transaction in
        self?.pushViewController(controller, animated: !transaction.disablesAnimations)
      } dismiss: { [weak self] controller, transaction in
        self?.popFromViewController(controller, animated: !transaction.disablesAnimations)
      }
    }

    @discardableResult
    func popFromViewController(
      _ controller: UIViewController, animated: Bool
    ) -> [UIViewController]? {
      guard let index = viewControllers.firstIndex(of: controller), index != 0 else { return nil }
      return popToViewController(viewControllers[index - 1], animated: animated)
    }
  }

  private class Presented {
    weak var controller: UIViewController?
    let presentationID: AnyHashable?
    init(_ controller: UIViewController, id presentationID: AnyHashable? = nil) {
      self.controller = controller
      self.presentationID = presentationID
    }
  }

  extension UIViewController {
    static let installSwizzles: () = {
      if let original = class_getInstanceMethod(
        UIViewController.self, #selector(UIViewController.viewDidAppear)
      ),
        let swizzled = class_getInstanceMethod(
          UIViewController.self, #selector(UIViewController.UIKitNavigation_viewDidAppear)
        )
      {
        method_exchangeImplementations(original, swizzled)
      }
      if let original = class_getInstanceMethod(
        UIViewController.self, #selector(UIViewController.viewDidDisappear)
      ),
        let swizzled = class_getInstanceMethod(
          UIViewController.self, #selector(UIViewController.UIKitNavigation_viewDidDisappear)
        )
      {
        method_exchangeImplementations(original, swizzled)
      }
    }()

    @objc fileprivate func UIKitNavigation_viewDidAppear(_ animated: Bool) {
      guard hasViewAppeared else {
        hasViewAppeared = true
        for presentation in onViewAppear {
          presentation()
        }
        onViewAppear.removeAll()
        return
      }
      UIKitNavigation_viewDidAppear(animated)
    }

    @objc fileprivate func UIKitNavigation_viewDidDisappear(_ animated: Bool) {
      UIKitNavigation_viewDidDisappear(animated)
      if isBeingDismissed || isMovingFromParent, let onDismiss {
        onDismiss()
        self.onDismiss = nil
      }
    }
  }

  extension Bool {
    fileprivate struct Unit: Hashable, Identifiable {
      var id: Unit { self }
    }

    fileprivate var toOptionalUnit: Unit? {
      get { self ? Unit() : nil }
      set { self = newValue != nil }
    }
  }
#endif
