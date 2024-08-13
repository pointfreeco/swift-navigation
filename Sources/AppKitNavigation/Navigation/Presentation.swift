#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import IssueReporting
@_spi(Internals) import SwiftNavigation
import AppKit
import AppKitNavigationShim

extension NSViewController {
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
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> NSViewController
    ) -> ObservationToken {
        present(item: isPresented.toOptionalUnit, style: style, onDismiss: onDismiss) { _ in content() }
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
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> NSViewController
    ) -> ObservationToken {
        present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
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
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObservationToken {
        present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
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
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> NSViewController
    ) -> ObservationToken {
        present(item: item, id: id, style: style, onDismiss: onDismiss) {
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
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObservationToken {
        destination(item: item, id: id) { $item in
            content($item)
        } present: { [weak self] child, transaction in
            guard let self else { return }
            if presentedViewControllers != nil {
                self.dismiss(nil)
                    onDismiss?()
                    self.present(child, for: style)
                
            } else {
                self.present(child, for: style)
            }
        } dismiss: { [weak self] _, transaction in
            self?.dismiss(nil)
            onDismiss?()
        }
    }

    
    public enum TransitionStyle {
        case sheet
        case modalWindow
        case popover(rect: NSRect, view: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)
        case custom(NSViewControllerPresentationAnimator)
    }

    fileprivate func present(_ viewControllerToPresent: NSViewController, for style: TransitionStyle) {
        switch style {
        case .sheet:
            presentAsSheet(viewControllerToPresent)
        case .modalWindow:
            presentAsModalWindow(viewControllerToPresent)
        case .popover(let rect, let view, let preferredEdge, let behavior):
            present(viewControllerToPresent, asPopoverRelativeTo: rect, of: view, preferredEdge: preferredEdge, behavior: behavior)
        case .custom(let animator):
            present(viewControllerToPresent, animator: animator)
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
        content: @escaping () -> NSViewController,
        present: @escaping (NSViewController, UITransaction) -> Void,
        dismiss: @escaping (
            _ child: NSViewController,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        destination(
            item: isPresented.toOptionalUnit,
            content: { _ in content() },
            present: present,
            dismiss: dismiss
        )
    }

    /// Presents a view controller using the given item as a data source for its content.
    ///
    /// This helper powers ``navigationDestination(item:content:)-367r6`` and can be used to define
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
        content: @escaping (UIBinding<Item>) -> NSViewController,
        present: @escaping (NSViewController, UITransaction) -> Void,
        dismiss: @escaping (
            _ child: NSViewController,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
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
    /// This helper powers ``present(item:onDismiss:content:)-34iup`` and can be used to define
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
        content: @escaping (UIBinding<Item>) -> NSViewController,
        present: @escaping (
            _ child: NSViewController,
            _ transaction: UITransaction
        ) -> Void,
        dismiss: @escaping (
            _ child: NSViewController,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
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
        content: @escaping (UIBinding<Item>) -> NSViewController,
        present: @escaping (
            _ child: NSViewController,
            _ transaction: UITransaction
        ) -> Void,
        dismiss: @escaping (
            _ child: NSViewController,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
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
                       presentationID == id(wrappedValue) {
                        item.wrappedValue = nil
                    }
                }
                childController.onDismiss = onDismiss
                
                self.presentedByID[key] = Presented(childController, id: id(unwrappedItem.wrappedValue))
                let work = {
                    withUITransaction(transaction) {
                        present(childController, transaction)
                    }
                }
                if hasViewAppeared {
                    work()
                } else {
                    onViewAppear.append(work)
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

@MainActor
private class Presented {
    weak var controller: NSViewController?
    let presentationID: AnyHashable?
    deinit {
        // NB: This can only be assumed because it is held in a UIViewController and is guaranteed to
        //     deinit alongside it on the main thread. If we use this other places we should force it
        //     to be a UIViewController as well, to ensure this functionality.
        MainActor._assumeIsolated {
            self.controller?.dismiss(nil)
        }
    }

    init(_ controller: NSViewController, id presentationID: AnyHashable? = nil) {
        self.controller = controller
        self.presentationID = presentationID
    }
}
#endif
