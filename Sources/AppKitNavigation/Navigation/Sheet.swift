#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
public protocol WindowProviderAdapter: NSObject {
    var currentWindow: NSWindow? { get }
    func beginSheet(for provider: WindowProviderAdapter) async
    func endSheet(for provider: WindowProviderAdapter)
}

extension WindowProviderAdapter {
    public func beginSheet(for provider: any WindowProviderAdapter) async {
        if let sheetedWindow = provider.currentWindow {
            await currentWindow?.beginSheet(sheetedWindow)
        }
    }

    public func endSheet(for provider: any WindowProviderAdapter) {
        if let sheetedWindow = provider.currentWindow {
            currentWindow?.endSheet(sheetedWindow)
        }
    }
}

extension NSWindow: WindowProviderAdapter {
    public var currentWindow: NSWindow? { self }
}

extension NSWindowController: WindowProviderAdapter {
    public var currentWindow: NSWindow? { window }
}

extension NSViewController: WindowProviderAdapter {
    public var currentWindow: NSWindow? { view.window }
}

extension NSAlert: WindowProviderAdapter {
    public var currentWindow: NSWindow? { window }

    public func beginSheet(for provider: any WindowProviderAdapter) async {
        guard let parentWindow = provider.currentWindow else { return }
        await beginSheetModal(for: parentWindow)
    }

    public func endSheet(for provider: any WindowProviderAdapter) {
        provider.currentWindow?.endSheet(window)
    }
}

extension WindowProviderAdapter {
    @discardableResult
    public func sheet<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> WindowProviderAdapter
    ) -> ObservationToken {
        sheet(item: item, id: id) { $item in
            content($item)
        } beginSheet: { [weak self] child, transaction in
            guard let self else { return }
            if let attachedSheetWindow = currentWindow?.attachedSheet {
                self.endSheet(for: attachedSheetWindow)
                onDismiss?()
                Task { @MainActor in
                    await self.beginSheet(for: child)
                    child.onEndSheet?.invoke()
                    child.onEndSheet = nil
                }
            } else {
                Task { @MainActor in
                    await self.beginSheet(for: child)
                    child.onEndSheet?.invoke()
                    child.onEndSheet = nil
                }
            }
        } endSheet: { [weak self] provider, transaction in
            self?.endSheet(for: provider)
            onDismiss?()
        }
    }

    private func sheet<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        content: @escaping (UIBinding<Item>) -> WindowProviderAdapter,
        beginSheet: @escaping (
            _ child: WindowProviderAdapter,
            _ transaction: UITransaction
        ) -> Void,
        endSheet: @escaping (
            _ child: WindowProviderAdapter,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        sheet(
            item: item,
            id: { $0[keyPath: id] },
            content: content,
            beginSheet: beginSheet,
            endSheet: endSheet
        )
    }

    private func sheet<Item>(
        item: UIBinding<Item?>,
        id: @escaping (Item) -> AnyHashable?,
        content: @escaping (UIBinding<Item>) -> WindowProviderAdapter,
        beginSheet: @escaping (
            _ child: WindowProviderAdapter,
            _ transaction: UITransaction
        ) -> Void,
        endSheet: @escaping (
            _ child: WindowProviderAdapter,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        let key = UIBindingIdentifier(item)
        return observe { [weak self] transaction in
            guard let self else { return }
            if let unwrappedItem = UIBinding(item) {
                if let presented = sheetedByID[key] {
                    guard let presentationID = presented.sheetID,
                          presentationID != id(unwrappedItem.wrappedValue)
                    else {
                        return
                    }
                }
                let childController = content(unwrappedItem)
                let onEndSheet = ClosureHolder { [presentationID = id(unwrappedItem.wrappedValue)] in
                    if let wrappedValue = item.wrappedValue,
                       presentationID == id(wrappedValue) {
                        item.wrappedValue = nil
                    }
                }
                childController.onEndSheet = onEndSheet

                self.sheetedByID[key] = Sheeted(childController, id: id(unwrappedItem.wrappedValue))
                let work = {
                    withUITransaction(transaction) {
                        beginSheet(childController, transaction)
                    }
                }
//                if hasViewAppeared {
                work()
//                } else {
//                    onViewAppear.append(work)
//                }
            } else if let presented = sheetedByID[key] {
                if let controller = presented.provider {
                    endSheet(controller, transaction)
                }
                self.sheetedByID[key] = nil
            }
        }
    }

    private var sheetedByID: [UIBindingIdentifier: Sheeted] {
        get {
            (objc_getAssociatedObject(self, sheetedKey)
                as? [UIBindingIdentifier: Sheeted])
                ?? [:]
        }
        set {
            objc_setAssociatedObject(
                self, sheetedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private var onEndSheet: ClosureHolder? {
        set {
            objc_setAssociatedObject(
                self, onEndSheetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        get {
            objc_getAssociatedObject(self, onEndSheetKey) as? ClosureHolder
        }
    }

//    func modal() {}
}

private class ClosureHolder: NSObject {
    let closure: () -> Void
    init(closure: @escaping () -> Void) {
        self.closure = closure
    }
    func invoke() {
        closure()
    }
}

private let onEndSheetKey = malloc(1)!
private let sheetedKey = malloc(1)!

@MainActor
private class Sheeted {
    weak var provider: WindowProviderAdapter?
    let sheetID: AnyHashable?
    deinit {
        // NB: This can only be assumed because it is held in a UIViewController and is guaranteed to
        //     deinit alongside it on the main thread. If we use this other places we should force it
        //     to be a UIViewController as well, to ensure this functionality.
        MainActor._assumeIsolated {
            self.provider?.currentWindow?.endSheeted()
        }
    }

    init(_ provider: WindowProviderAdapter? = nil, id: AnyHashable?) {
        self.provider = provider
        self.sheetID = id
    }
}

extension NSWindow {
    func endSheeted() {
        guard sheetParent != nil else {
            return
        }
        sheetParent?.endSheet(self)
    }
}


#endif
