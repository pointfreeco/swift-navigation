#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import Combine

@MainActor
extension NSObject {
    @discardableResult
    public func modal<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> ModalRepresentable
    ) -> ObservationToken {
        modal(item: item, id: id) { $item in
            content($item)
        } beginModal: { modalRepresentable, _ in
            if NSApplication.shared.modalWindow != nil {
                NSApplication.shared.stopModal()
                onDismiss?()
                DispatchQueue.main.async {
                    ModalWindowsObserver.shared.observeWindow(modalRepresentable.window)
                    modalRepresentable.runModal()
                    modalRepresentable.onEndModal?.invoke()
                    modalRepresentable.onEndModal = nil
                }

            } else {
                DispatchQueue.main.async {
                    ModalWindowsObserver.shared.observeWindow(modalRepresentable.window)
                    modalRepresentable.runModal()
                    modalRepresentable.onEndModal?.invoke()
                    modalRepresentable.onEndModal = nil
                }
            }
        } endModal: { provider, _ in
            NSApplication.shared.stopModal()
            onDismiss?()
        }
    }

    private func modal<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        content: @escaping (UIBinding<Item>) -> ModalRepresentable,
        beginModal: @escaping (
            _ child: ModalRepresentable,
            _ transaction: UITransaction
        ) -> Void,
        endModal: @escaping (
            _ child: ModalRepresentable,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        modal(
            item: item,
            id: { $0[keyPath: id] },
            content: content,
            beginModal: beginModal,
            endModal: endModal
        )
    }

    private func modal<Item>(
        item: UIBinding<Item?>,
        id: @escaping (Item) -> AnyHashable?,
        content: @escaping (UIBinding<Item>) -> ModalRepresentable,
        beginModal: @escaping (
            _ child: ModalRepresentable,
            _ transaction: UITransaction
        ) -> Void,
        endModal: @escaping (
            _ child: ModalRepresentable,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        let key = UIBindingIdentifier(item)
        return observe { [weak self] transaction in
            guard let self else { return }
            if let unwrappedItem = UIBinding(item) {
                if let presented = modaledByID[key] {
                    guard let presentationID = presented.modalID,
                          presentationID != id(unwrappedItem.wrappedValue)
                    else {
                        return
                    }
                }
                let modalRepresentable = content(unwrappedItem)
                let onEndSheet = ClosureHolder { [presentationID = id(unwrappedItem.wrappedValue)] in
                    if let wrappedValue = item.wrappedValue,
                       presentationID == id(wrappedValue) {
                        item.wrappedValue = nil
                    }
                }
                modalRepresentable.onEndModal = onEndSheet

                self.modaledByID[key] = Modaled(modalRepresentable, id: id(unwrappedItem.wrappedValue))
                let work = {
                    withUITransaction(transaction) {
                        beginModal(modalRepresentable, transaction)
                    }
                }
                work()
            } else if let modaled = modaledByID[key] {
                if let modalRepresentable = modaled.provider {
                    endModal(modalRepresentable, transaction)
                }
                self.modaledByID[key] = nil
            }
        }
    }

    private var modaledByID: [UIBindingIdentifier: Modaled] {
        get {
            (objc_getAssociatedObject(self, modaledKey)
                as? [UIBindingIdentifier: Modaled])
                ?? [:]
        }
        set {
            objc_setAssociatedObject(
                self, modaledKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private var onEndModal: ClosureHolder? {
        set {
            objc_setAssociatedObject(
                self, onEndModalKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        get {
            objc_getAssociatedObject(self, onEndModalKey) as? ClosureHolder
        }
    }
}

private let onEndModalKey = malloc(1)!
private let modaledKey = malloc(1)!

@MainActor
private class Modaled {
    weak var provider: ModalRepresentable?
    let modalID: AnyHashable?
    deinit {
        // NB: This can only be assumed because it is held in a UIViewController and is guaranteed to
        //     deinit alongside it on the main thread. If we use this other places we should force it
        //     to be a UIViewController as well, to ensure this functionality.
        MainActor._assumeIsolated {
            NSApplication.shared.stopModal()
        }
    }

    init(_ provider: ModalRepresentable? = nil, id: AnyHashable?) {
        self.provider = provider
        self.modalID = id
    }
}
#endif
