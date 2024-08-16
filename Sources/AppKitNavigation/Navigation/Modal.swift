#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import Combine

@MainActor
private var modalObserverKeys = AssociatedKeys()

private typealias ModalObserver<Content: ModalContent> = NavigationObserver<NSObject, Content>

@MainActor
extension NSObject {
    /// Sheet a representable modally when a binding to a Boolean value you provide is true.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for AppKit.
    ///
    /// - Parameters:
    ///   - isSheeted: A binding to a Boolean value that determines whether to sheet the representable
    ///   - onDismiss: The closure to execute when dismissing the representable.
    ///   - content: A closure that returns the representable to display over the current window content.
    @discardableResult
    public func modal<Content: ModalContent>(
        isModaled: UIBinding<Bool>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> Content
    ) -> ObservationToken {
        modal(item: isModaled.toOptionalUnit, onDismiss: onDismiss) { _ in content() }
    }

    /// Sheet a representable modally when a binding to a Boolean value you provide is true.
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
    public func modal<Item: Identifiable, Content: ModalContent>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObservationToken {
        modal(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    /// Sheet a representable modally when a binding to a Boolean value you provide is true.
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
    public func modal<Item: Identifiable, Content: ModalContent>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObservationToken {
        modal(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    /// Sheet a representable modally when a binding to a Boolean value you provide is true.
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
    public func modal<Item, ID: Hashable, Content: ModalContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObservationToken {
        modal(item: item, id: id, onDismiss: onDismiss) {
            content($0.wrappedValue)
        }
    }
    
    @discardableResult
    public func modal<Item, ID: Hashable, Content: ModalContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObservationToken {
        modal(item: item, id: id) { $item in
            content($item)
        } beginModal: { modalContent, _ in
            if NSApplication.shared.modalWindow != nil {
                NSApplication.shared.stopModal()
                onDismiss?()
                DispatchQueue.main.async {
                    ModalWindowsObserver.shared.observeWindow(modalContent.window)
                    modalContent.runModal()
                    modalContent.onEndNavigation?()
                    modalContent.onEndNavigation = nil
                }

            } else {
                DispatchQueue.main.async {
                    ModalWindowsObserver.shared.observeWindow(modalContent.window)
                    modalContent.runModal()
                    modalContent.onEndNavigation?()
                    modalContent.onEndNavigation = nil
                }
            }
        } endModal: { _, _ in
            NSApplication.shared.stopModal()
            onDismiss?()
        }
    }

    private func modal<Item, ID: Hashable, Content: ModalContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        content: @escaping (UIBinding<Item>) -> Content,
        beginModal: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void,
        endModal: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        let modalObserver: ModalObserver<Content> = modalObserver()
        return modalObserver.observe(
            item: item,
            id: { $0[keyPath: id] },
            content: content,
            begin: beginModal,
            end: endModal
        )
    }

    private func modalObserver<Content: ModalContent>() -> ModalObserver<Content> {
        if let observer = objc_getAssociatedObject(self, modalObserverKeys.key(of: Content.self)) as? ModalObserver<Content> {
            return observer
        } else {
            let observer = ModalObserver<Content>(owner: self)
            objc_setAssociatedObject(self, modalObserverKeys.key(of: Content.self), observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return observer
        }
    }
}

extension Navigated where Content: ModalContent {
    func clearup() {
        NSApplication.shared.stopModal()
    }
}

#endif
