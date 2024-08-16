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
    ) -> ObservationToken {
        let key = UIBindingIdentifier(item)
        return observe { [weak self] transaction in
            guard let self else { return }
            if let unwrappedItem = UIBinding(item) {
                if let presented = navigatedByID[key] {
                    guard let presentationID = presented.id,
                          presentationID != id(unwrappedItem.wrappedValue)
                    else {
                        return
                    }
                }
                let content = content(unwrappedItem)
                let onEndNavigation = { [presentationID = id(unwrappedItem.wrappedValue)] in
                    if let wrappedValue = item.wrappedValue,
                       presentationID == id(wrappedValue) {
                        item.wrappedValue = nil
                    }
                }
                content.onEndNavigation = onEndNavigation

                self.navigatedByID[key] = Navigated(content, id: id(unwrappedItem.wrappedValue))
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
