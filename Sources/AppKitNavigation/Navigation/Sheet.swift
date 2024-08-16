#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

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
    public func sheet(
        isSheeted: UIBinding<Bool>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> SheetContent
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
    public func sheet<Item: Identifiable>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> SheetContent
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
    public func sheet<Item: Identifiable>(
        item: UIBinding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> SheetContent
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
    public func sheet<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> SheetContent
    ) -> ObservationToken {
        sheet(item: item, id: id, onDismiss: onDismiss) {
            content($0.wrappedValue)
        }
    }

    @discardableResult
    public func sheet<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (UIBinding<Item>) -> SheetContent
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

    private func sheet<Item, ID: Hashable>(
        item: UIBinding<Item?>,
        id: KeyPath<Item, ID>,
        content: @escaping (UIBinding<Item>) -> SheetContent,
        beginSheet: @escaping (
            _ child: SheetContent,
            _ transaction: UITransaction
        ) -> Void,
        endSheet: @escaping (
            _ child: SheetContent,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        sheetObserver.observe(
            item: item,
            id: { $0[keyPath: id] },
            content: content,
            begin: beginSheet,
            end: endSheet
        )
    }

    private func sheet<Item>(
        item: UIBinding<Item?>,
        id: @escaping (Item) -> AnyHashable?,
        content: @escaping (UIBinding<Item>) -> SheetContent,
        beginSheet: @escaping (
            _ child: SheetContent,
            _ transaction: UITransaction
        ) -> Void,
        endSheet: @escaping (
            _ child: SheetContent,
            _ transaction: UITransaction
        ) -> Void
    ) -> ObservationToken {
        let key = UIBindingIdentifier(item)
        return observe { [weak self] transaction in
            guard let self else { return }
            if let unwrappedItem = UIBinding(item) {
                if let presented = sheetedByID[key] {
                    guard let presentationID = presented.id,
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
                work()
            } else if let presented = sheetedByID[key] {
                if let controller = presented.content {
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

    private var sheetObserver: SheetObserver {
        set {
            objc_setAssociatedObject(self, sheetObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let observer = objc_getAssociatedObject(self, sheetObserverKey) as? SheetObserver {
                return observer
            } else {
                let observer = SheetObserver(owner: self)
                self.sheetObserver = observer
                return observer
            }
        }
    }
}

private typealias SheetObserver = NavigationObserver<SheetContent, SheetContent>
private let sheetObserverKey = malloc(1)!
private let onEndSheetKey = malloc(1)!
private let sheetedKey = malloc(1)!

@MainActor
private class Sheeted: NavigatedProtocol {
    weak var content: (any SheetContent)?
    let id: AnyHashable?
    deinit {
        // NB: This can only be assumed because it is held in a UIViewController and is guaranteed to
        //     deinit alongside it on the main thread. If we use this other places we should force it
        //     to be a UIViewController as well, to ensure this functionality.
        MainActor._assumeIsolated {
            self.content?.currentWindow?.endSheeted()
        }
    }

    required init(_ content: any SheetContent, id: AnyHashable?) {
        self.content = content
        self.id = id
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
        self.content?.currentWindow?.endSheeted()
    }
}

#endif
