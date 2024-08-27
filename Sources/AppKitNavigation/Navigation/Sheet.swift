#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

private typealias SheetObserver<FromContent: SheetContent, ToContent: SheetContent> = NavigationObserver<FromContent, ToContent>

@MainActor
private var sheetObserverKeys = AssociatedKeys()

extension SheetContent {
    @discardableResult
    public func sheet<Content: SheetContent>(
        isSheeted: UIBinding<Bool>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> Content
    ) -> ObserveToken {
        sheet(item: isSheeted.toOptionalUnit, onDismiss: onDismiss) { _ in content() }
    }

    @discardableResult
    public func sheet<Item: Identifiable, Content: SheetContent>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObserveToken {
        sheet(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    @_disfavoredOverload
    @discardableResult
    public func sheet<Item: Identifiable, Content: SheetContent>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
        sheet(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    @discardableResult
    public func sheet<Item, ID: Hashable, Content: SheetContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObserveToken {
        sheet(item: item, id: id, onDismiss: onDismiss) {
            content($0.wrappedValue)
        }
    }

    @discardableResult
    public func sheet<Item, ID: Hashable, Content: SheetContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObserveToken {
        sheet(item: item, id: id) { $item in
            content($item)
        } beginSheet: { [weak self] child, _ in
            guard let self else { return }
            if let attachedSheetWindow = currentWindow?.attachedSheet {
                self.endSheet(for: attachedSheetWindow)
                onDismiss?()
                Task { @MainActor in
                    await self.beginSheet(for: child)
                    child.onEndNavigation?()
                    child.onEndNavigation = nil
                }
            } else {
                Task { @MainActor in
                    await self.beginSheet(for: child)
                    child.onEndNavigation?()
                    child.onEndNavigation = nil
                }
            }
        } endSheet: { [weak self] content, _ in
            self?.endSheet(for: content)
            onDismiss?()
        }
    }

    private func sheet<Item, ID: Hashable, Content: SheetContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        content: @escaping (UIBinding<Item>) -> Content,
        beginSheet: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void,
        endSheet: @escaping (
            _ child: Content,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObserveToken {
        let sheetObserver: SheetObserver<Self, Content> = sheetObserver()
        return sheetObserver.observe(
            item: item,
            id: { $0[keyPath: id] },
            content: content,
            begin: beginSheet,
            end: endSheet
        )
    }

    private func sheetObserver<Content: SheetContent>() -> SheetObserver<Self, Content> {
        if let observer = objc_getAssociatedObject(self, sheetObserverKeys.key(of: Content.self)) as? SheetObserver<Self, Content> {
            return observer
        } else {
            let observer = SheetObserver<Self, Content>(owner: self)
            objc_setAssociatedObject(self, sheetObserverKeys.key(of: Content.self), observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return observer
        }
    }
}

extension Navigated where Content: SheetContent {
    func clearup() {
        guard let window = content?.currentWindow else { return }
        window.sheetParent?.endSheet(window)
    }
}

#endif
