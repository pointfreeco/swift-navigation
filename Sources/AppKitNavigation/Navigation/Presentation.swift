#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import SwiftNavigation
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
    @discardableResult
    public func present<Content: PresentationContent>(
        isPresented: UIBinding<Bool>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> Content
    ) -> ObserveToken {
        present(item: isPresented.toOptionalUnit, style: style, onDismiss: onDismiss) { _ in content() }
    }

    @discardableResult
    public func present<Item: Identifiable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObserveToken {
        present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    @_disfavoredOverload
    @discardableResult
    public func present<Item: Identifiable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
        present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    @discardableResult
    public func present<Item, ID: Hashable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObserveToken {
        present(item: item, id: id, style: style, onDismiss: onDismiss) {
            content($0.wrappedValue)
        }
    }

    @_disfavoredOverload
    @discardableResult
    public func present<Item, ID: Hashable, Content: PresentationContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        style: TransitionStyle,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
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

    @discardableResult
    public func destination<Content: PresentationContent>(
        isPresented: UIBinding<Bool>,
        content: @escaping () -> Content,
        present: @escaping (Content, UITransaction) -> Void,
        dismiss: @escaping (
            _ child: Content,
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
    public func destination<Item, Content: PresentationContent>(
        item: UIBinding<Item?>,
        content: @escaping (UIBinding<Item>) -> Content,
        present: @escaping (Content, UITransaction) -> Void,
        dismiss: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObserveToken {
        let presentationObserver: PresentationObserver<Content> = presentationObserver()
        return presentationObserver.observe(
            item: item,
            id: { _ in nil },
            content: content,
            begin: present,
            end: dismiss
        )
    }

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
    ) -> ObserveToken {
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
