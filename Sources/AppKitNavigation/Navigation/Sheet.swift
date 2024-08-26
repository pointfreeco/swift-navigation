#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

private typealias SheetObserver<FromContent: SheetContent, ToContent: SheetContent> = NavigationObserver<FromContent, ToContent>

@MainActor
private var sheetObserverKeys = AssociatedKeys()

extension SheetContent {
    /// Sheet a representable modally when a binding to a Boolean value you provide is true.
    ///
    /// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for AppKit.
    ///
    /// - Parameters:
    ///   - isSheeted: A binding to a Boolean value that determines whether to sheet the representable
    ///   - onDismiss: The closure to execute when dismissing the representable.
    ///   - content: A closure that returns the representable to display over the current window content.
    @discardableResult
    public func sheet<Content: SheetContent>(
        isSheeted: UIBinding<Bool>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> Content
    ) -> ObservationToken {
        sheet(item: isSheeted.toOptionalUnit, onDismiss: onDismiss) { _ in content() }
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
    public func sheet<Item: Identifiable, Content: SheetContent>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObservationToken {
        sheet(item: item, id: \.id, onDismiss: onDismiss, content: content)
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
    public func sheet<Item: Identifiable, Content: SheetContent>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> Content
    ) -> ObservationToken {
        sheet(item: item, id: \.id, onDismiss: onDismiss, content: content)
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
    public func sheet<Item, ID: Hashable, Content: SheetContent>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> ObservationToken {
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
    ) -> ObservationToken {
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
    ) -> ObservationToken {
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

extension NSWindow {
    func endSheeted() {
        guard sheetParent != nil else {
            return
        }
        sheetParent?.endSheet(self)
    }
}

extension Navigated where Content: SheetContent {
    func clearup() {
        content?.currentWindow?.endSheeted()
    }
}

#endif
