#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import Foundation
import SwiftNavigation

@MainActor
class NavigationObserver<Owner: AnyObject, Content: NavigationContent>: NSObject {
  private var navigatedByID: [UIBindingIdentifier: Navigated<Content>] = [:]

  unowned let owner: Owner

  init(owner: Owner) {
    self.owner = owner
    super.init()
  }

  func observe<Item>(
    item: UIBinding<Item?>,
    id: @escaping (Item) -> AnyHashable?,
    content: @escaping (UIBinding<Item>) -> Content,
    begin: @escaping (
      _ content: Content,
      _ transaction: UITransaction
    ) -> Void,
    end: @escaping (
      _ content: Content,
      _ transaction: UITransaction
    ) -> Void
  ) -> ObserveToken {
    let key = UIBindingIdentifier(item)
    return observe { [weak self] transaction in
      guard let self else { return }
      if let unwrappedItem = UIBinding(item) {
        if let navigated = navigatedByID[key] {
          if navigated.hasEnded {
            // NB: The content was closed from its own UI, and the binding was set again before
            //     this re-ran, so the 'nil' in between was never observed. Finish the old
            //     navigation before starting the new one instead of mistaking it for live.
            if let content = navigated.content {
              end(content, transaction)
            }
            navigatedByID[key] = nil
          } else {
            guard let navigationID = navigated.id,
                  navigationID != id(unwrappedItem.wrappedValue)
            else {
              return
            }
          }
        }
        let content = content(unwrappedItem)
        let navigated = Navigated(content, id: id(unwrappedItem.wrappedValue))
        let onEndNavigation = { [weak navigated, navigationID = id(unwrappedItem.wrappedValue)] in
          navigated?.hasEnded = true
          if let wrappedValue = item.wrappedValue,
             navigationID == id(wrappedValue) {
            item.wrappedValue = nil
          }
        }
        content.onEndNavigation = onEndNavigation

        self.navigatedByID[key] = navigated
        let work = {
          withUITransaction(transaction) {
            begin(content, transaction)
          }
        }
        commitWork(work)
      } else if let navigated = navigatedByID[key] {
        if let content = navigated.content {
          end(content, transaction)
        }
        self.navigatedByID[key] = nil
      }
    }
  }

  func commitWork(_ work: @escaping () -> Void) {
    work()
  }
}

@MainActor
class Navigated<Content: NavigationContent> {
  weak var content: Content?
  let id: AnyHashable?
  /// Whether the content has already ended on its own, closed from its own UI rather than through
  /// the binding.
  var hasEnded = false
  func clearup() {}
  deinit {
    MainActor._assumeIsolated {
      clearup()
    }
  }

  required init(_ content: Content, id: AnyHashable?) {
    self.content = content
    self.id = id
  }
}

#endif
