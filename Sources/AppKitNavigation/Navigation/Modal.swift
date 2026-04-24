#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
private var ModalObserverKeys = AssociatedKeys()

private typealias ModalObserver<Content: ModalContent> = NavigationObserver<NSObject, Content>

// MARK: - Modal Session - NSWindow

@MainActor
extension NSObject {
  @discardableResult
  public func modalSession(
    isModaled: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSWindow
  ) -> ObserveToken {
    _modalSession(isModaled: isModaled, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modalSession<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSWindow
  ) -> ObserveToken {
    _modalSession(item: item, onDismiss: onDismiss, content: content)
  }

  @_disfavoredOverload
  @discardableResult
  public func modalSession<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSWindow
  ) -> ObserveToken {
    _modalSession(item: item, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modalSession<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSWindow
  ) -> ObserveToken {
    _modalSession(item: item, id: id, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modalSession<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSWindow
  ) -> ObserveToken {
    _modalSession(item: item, id: id, onDismiss: onDismiss, content: content)
  }
}

// MARK: - Modal - NSWindow

@MainActor
extension NSObject {
  @discardableResult
  public func modal(
    isModaled: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSWindow
  ) -> ObserveToken {
    _modal(isModaled: isModaled, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSWindow
  ) -> ObserveToken {
    _modal(item: item, onDismiss: onDismiss, content: content)
  }

  @_disfavoredOverload
  @discardableResult
  public func modal<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSWindow
  ) -> ObserveToken {
    _modal(item: item, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSWindow
  ) -> ObserveToken {
    _modal(item: item, id: id, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSWindow
  ) -> ObserveToken {
    _modal(item: item, id: id, onDismiss: onDismiss, content: content)
  }
}

// MARK: - Modal - NSAlert

@MainActor
extension NSObject {
  @discardableResult
  public func modal(
    isModaled: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSAlert
  ) -> ObserveToken {
    _modal(isModaled: isModaled, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSAlert
  ) -> ObserveToken {
    _modal(item: item, onDismiss: onDismiss, content: content)
  }

  @_disfavoredOverload
  @discardableResult
  public func modal<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSAlert
  ) -> ObserveToken {
    _modal(item: item, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSAlert
  ) -> ObserveToken {
    _modal(item: item, id: id, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSAlert
  ) -> ObserveToken {
    _modal(item: item, id: id, onDismiss: onDismiss, content: content)
  }
}

// MARK: - Modal - NSSavePanel

@MainActor
extension NSObject {
  @discardableResult
  public func modal(
    isModaled: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSSavePanel
  ) -> ObserveToken {
    _modal(isModaled: isModaled, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSSavePanel
  ) -> ObserveToken {
    _modal(item: item, onDismiss: onDismiss, content: content)
  }

  @_disfavoredOverload
  @discardableResult
  public func modal<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSSavePanel
  ) -> ObserveToken {
    _modal(item: item, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSSavePanel
  ) -> ObserveToken {
    _modal(item: item, id: id, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  public func modal<Item, ID: Hashable>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> NSSavePanel
  ) -> ObserveToken {
    _modal(item: item, id: id, onDismiss: onDismiss, content: content)
  }
}

// MARK: - Private Modal

@MainActor
extension NSObject {
  @discardableResult
  fileprivate func _modal<Content: ModalContent>(
    isModaled: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> Content
  ) -> ObserveToken {
    _modal(item: isModaled.toOptionalUnit, onDismiss: onDismiss) { _ in content() }
  }

  @discardableResult
  fileprivate func _modal<Item: Identifiable, Content: ModalContent>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> Content
  ) -> ObserveToken {
    _modal(item: item, id: \.id, onDismiss: onDismiss, content: content)
  }

  @_disfavoredOverload
  @discardableResult
  fileprivate func _modal<Item: Identifiable, Content: ModalContent>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> Content
  ) -> ObserveToken {
    _modal(item: item, id: \.id, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  fileprivate func _modal<Item, ID: Hashable, Content: ModalContent>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> Content
  ) -> ObserveToken {
    _modal(item: item, id: id, onDismiss: onDismiss) {
      content($0.wrappedValue)
    }
  }

  @discardableResult
  fileprivate func _modal<Item, ID: Hashable, Content: ModalContent>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> Content
  ) -> ObserveToken {
    _modal(item: item, id: id) { $item in
      content($item)
    } beginModal: { modalContent, _ in
      if NSApplication.shared.modalWindow != nil {
        NSApplication.shared.stopModal()
        onDismiss?()
        DispatchQueue.main.async {
          ModalWindowsObserver.shared.observeWindow(modalContent.window)
          modalContent.appKitNavigationRunModal()
          modalContent.onEndNavigation?()
          modalContent.onEndNavigation = nil
        }

      } else {
        DispatchQueue.main.async {
          ModalWindowsObserver.shared.observeWindow(modalContent.window)
          modalContent.appKitNavigationRunModal()
          modalContent.onEndNavigation?()
          modalContent.onEndNavigation = nil
        }
      }
    } endModal: { _, _ in
      NSApplication.shared.stopModal()
      onDismiss?()
    }
  }

  // MARK: - Modal Session

  @discardableResult
  fileprivate func _modalSession<Content: ModalSessionContent>(
    isModaled: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> Content
  ) -> ObserveToken {
    _modalSession(item: isModaled.toOptionalUnit, onDismiss: onDismiss) { _ in content() }
  }

  @discardableResult
  fileprivate func _modalSession<Item: Identifiable, Content: ModalSessionContent>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> Content
  ) -> ObserveToken {
    _modalSession(item: item, id: \.id, onDismiss: onDismiss, content: content)
  }

  @_disfavoredOverload
  @discardableResult
  fileprivate func _modalSession<Item: Identifiable, Content: ModalSessionContent>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> Content
  ) -> ObserveToken {
    _modalSession(item: item, id: \.id, onDismiss: onDismiss, content: content)
  }

  @discardableResult
  fileprivate func _modalSession<Item, ID: Hashable, Content: ModalSessionContent>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> Content
  ) -> ObserveToken {
    _modalSession(item: item, id: id, onDismiss: onDismiss) {
      content($0.wrappedValue)
    }
  }

  @discardableResult
  fileprivate func _modalSession<Item, ID: Hashable, Content: ModalSessionContent>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, ID>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> Content
  ) -> ObserveToken {
    _modal(item: item, id: id) { $item in
      content($item)
    } beginModal: { modalContent, _ in
      if let modaledWindow = NSApplication.shared.modalWindow, let modalSession = ModalWindowsObserver.shared.modalSessionByWindow[modaledWindow] {
        NSApplication.shared.endModalSession(modalSession)
        modaledWindow.window.close()
        onDismiss?()
        DispatchQueue.main.async {
          let modalSession = modalContent.appKitNavigationBeginModalSession()
          ModalWindowsObserver.shared.observeWindow(modalContent.window, modalSession: modalSession)
        }

      } else {
        DispatchQueue.main.async {
          let modalSession = modalContent.appKitNavigationBeginModalSession()
          ModalWindowsObserver.shared.observeWindow(modalContent.window, modalSession: modalSession)
        }
      }
    } endModal: { modalContent, _ in
      if let modalSession = ModalWindowsObserver.shared.modalSessionByWindow[modalContent.window] {
        NSApplication.shared.endModalSession(modalSession)
        modalContent.window.close()
        onDismiss?()
      }
    }
  }

  private func _modal<Item, ID: Hashable, Content: ModalContent>(
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
  ) -> ObserveToken {
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
    if let observer = objc_getAssociatedObject(self, ModalObserverKeys.key(of: Content.self)) as? ModalObserver<Content> {
      return observer
    } else {
      let observer = ModalObserver<Content>(owner: self)
      objc_setAssociatedObject(self, ModalObserverKeys.key(of: Content.self), observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
