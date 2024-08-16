#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import IssueReporting
@_spi(Internals) import SwiftNavigation
import AppKit
import AppKitNavigationShim

@MainActor
private var presentationObserverKeys = AssociatedKeys()

class PresentationObserver<Content: PresentationContent>: NavigationObserver<NSViewController, Content> {
    override func commitWork(_ work: @escaping () -> Void) {
        if owner.hasViewAppeared {
            work()
        } else {
            owner.onViewAppear.append(work)
        }
    }
}

extension NSViewController {
    /// Presents a view controller modally when a binding to a Boolean value you provide is true.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for AppKit.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the view
    ///     controller.
    ///   - onDismiss: The closure to execute when dismissing the view controller.
    ///   - content: A closure that returns the view controller to display over the current view
    ///     controller's content.
    @discardableResult
    public func present<Content: PresentationContent>(
        isPresented: UIBinding<Bool>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> Content
    ) -> ObservationToken {
        present(item: isPresented.toOptionalUnit, style: style, onDismiss: onDismiss) { _ in content() }
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for AppKit.
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
    public func present<Item: Identifiable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObservationToken {
        present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for AppKit.
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
    public func present<Item: Identifiable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObservationToken {
        present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for AppKit.
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
    public func present<Item, ID: Hashable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObservationToken {
        present(item: item, id: id, style: style, onDismiss: onDismiss) {
            content($0.wrappedValue)
        }
    }

    /// Presents a view controller modally using the given item as a data source for its content.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for AppKit.
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
    public func present<Item, ID: Hashable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObservationToken {
        destination(item: item, id: id) { $item in
            content($item)
        } present: { [weak self] child, transaction in
            guard let self else { return }
            if let presentedViewController = presentedViewControllers?.first {
                self.dismiss(presentedViewController)
                onDismiss?()
                child.presented(from: self, style: style)
            } else {
                child.presented(from: self, style: style)
            }
        } dismiss: { [weak self] child, transaction in
            guard let self else { return }
            child.dismiss(from: self)
            onDismiss?()
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
    public func destination<Content: PresentationContent>(
        isPresented: UIBinding<Bool>,
        content: @escaping () -> Content,
        present: @escaping (Content, UITransaction) -> Void,
        dismiss: @escaping (
            _ child: Content,
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
    public func destination<Item, Content: PresentationContent>(
        item: UIBinding<Item?>,
        content: @escaping (UIBinding<Item>) -> Content,
        present: @escaping (Content, UITransaction) -> Void,
        dismiss: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        let presentationObserver: PresentationObserver<Content> = presentationObserver()
        return presentationObserver.observe(
            item: item,
            id: { _ in nil },
            content: content,
            begin: present,
            end: dismiss
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
    public func destination<Item, ID: Hashable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        content: @escaping (UIBinding<Item>) -> Content,
        present: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void,
        dismiss: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
//        destination(
//            item: item,
//            id: { $0[keyPath: id] },
//            content: content,
//            present: present,
//            dismiss: dismiss
//        )
        let presentationObserver: PresentationObserver<Content> = presentationObserver()
        return presentationObserver.observe(item: item, id: { $0[keyPath: id] }, content: content, begin: present, end: dismiss)
    }

    private func presentationObserver<Content: PresentationContent>() -> PresentationObserver<Content> {
        if let observer = objc_getAssociatedObject(self, presentationObserverKeys.key(of: Content.self)) as? PresentationObserver<Content> {
            return observer
        } else {
            let observer = PresentationObserver<Content>(owner: self)
            objc_setAssociatedObject(self, presentationObserverKeys.key(of: Content.self), observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return observer
        }
    }
}

extension NavigationContent where Self: NSViewController {
    var _onEndNavigation: (() -> Void)? {
        set {
            onDismiss = newValue
        }
        get {
            onDismiss
        }
    }
}

extension Navigated where Content: NSViewController {
    func clearup() {
        content?.dismiss(nil)
    }
}

#endif
