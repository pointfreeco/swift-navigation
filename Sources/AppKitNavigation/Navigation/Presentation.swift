#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import SwiftNavigation
import AppKit
import AppKitNavigationShim

class PresentationObserver: NavigationObserver<NSViewController, NSViewController> {
    override func commitWork(_ work: @escaping () -> Void) {
        if owner._AppKitNavigation_hasViewAppeared {
            work()
        } else {
            owner._AppKitNavigation_onViewAppear.append(work)
        }
    }
}

extension NSViewController {
    @discardableResult
    public func present(
        isPresented: UIBinding<Bool>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> NSViewController
    ) -> ObserveToken {
        present(item: isPresented.toOptionalUnit, style: style, onDismiss: onDismiss) { _ in content() }
    }

    @discardableResult
    public func present<Item: Identifiable>(
        item: UIBinding<Item?>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
        present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

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

    @discardableResult
    public func present<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
        present(item: item, id: id, style: style, onDismiss: onDismiss) {
            content($0.wrappedValue)
        }
    }

    @_disfavoredOverload
    @discardableResult
    public func present<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
        destination(item: item, id: id) { $item in
            content($item)
        } present: { [weak self] child, transaction in
            guard let self else { return }
            if let presentedViewController = presentedViewControllers?.first {
                self.dismiss(presentedViewController)
                onDismiss?()
                self.present(child, for: style)
            } else {
                self.present(child, for: style)
            }
        } dismiss: { [weak self] child, transaction in
            guard let self else { return }
            self.dismiss(child)
            onDismiss?()
        }
    }

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
        let presentationObserver: PresentationObserver = presentationObserver()
        return presentationObserver.observe(
            item: item,
            id: { _ in nil },
            content: content,
            begin: present,
            end: dismiss
        )
    }

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
    ) -> ObserveToken {
        let presentationObserver: PresentationObserver = presentationObserver()
        return presentationObserver.observe(item: item, id: { $0[keyPath: id] }, content: content, begin: present, end: dismiss)
    }

    private static var presentationObserverKey = malloc(1)!
    
    private func presentationObserver() -> PresentationObserver {
        if let observer = objc_getAssociatedObject(self, Self.presentationObserverKey) as? PresentationObserver {
            return observer
        } else {
            let observer = PresentationObserver(owner: self)
            objc_setAssociatedObject(self, Self.presentationObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return observer
        }
    }
    
    public enum TransitionStyle {
        case sheet
        case modalWindow
        case popover(rect: NSRect, view: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)
        case custom(NSViewControllerPresentationAnimator)
    }

    private func present(_ viewControllerToPresent: NSViewController, for style: TransitionStyle) {
        switch style {
        case .sheet:
            presentAsSheet(viewControllerToPresent)
        case .modalWindow:
            presentAsModalWindow(viewControllerToPresent)
        case let .popover(rect, view, preferredEdge, behavior):
            present(viewControllerToPresent, asPopoverRelativeTo: rect, of: view, preferredEdge: preferredEdge, behavior: behavior)
        case let .custom(animator):
            present(viewControllerToPresent, animator: animator)
        }
    }
}

extension NavigationContent where Self: NSViewController {
    var _onEndNavigation: (() -> Void)? {
        set {
            _AppKitNavigation_onDismiss = newValue
        }
        get {
            _AppKitNavigation_onDismiss
        }
    }
}

extension Navigated where Content: NSViewController {
    func clearup() {
        content?.dismiss(nil)
    }
}

#endif
