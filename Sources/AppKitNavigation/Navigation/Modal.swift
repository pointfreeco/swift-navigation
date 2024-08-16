#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import Combine

@MainActor
extension NSObject {
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

private let modalObserverKey = malloc(1)!
@MainActor
private var modalObserverKeys = AssociatedKeys()
private typealias ModalObserver<Content: ModalContent> = NavigationObserver<NSObject, Content>

extension Navigated where Content: ModalContent {
    func clearup() {
        NSApplication.shared.stopModal()
    }
}

#endif
