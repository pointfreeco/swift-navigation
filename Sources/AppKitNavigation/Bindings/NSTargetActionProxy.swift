#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import IdentifiedCollections

@MainActor
class NSTargetActionProxy: NSObject {
    typealias ActionClosure = (Any?) -> Void

    typealias ActionIdentifier = UUID

    private struct Action: Identifiable {
        let id = UUID()

        var closure: ActionClosure

        func invoke(_ sender: Any?) {
            closure(sender)
        }
    }

    private var bindingActions: IdentifiedArrayOf<Action> = []

    private var actions: IdentifiedArrayOf<Action> = []

    private var originTarget: AnyObject?

    private var originAction: Selector?

    weak var owner: NSTargetActionProtocol?

    required init(owner: NSTargetActionProtocol) {
        self.owner = owner
        super.init()
        self.originTarget = owner.appkitNavigationTarget
        self.originAction = owner.appkitNavigationAction
        owner.appkitNavigationTarget = self
        owner.appkitNavigationAction = #selector(invokeAction(_:))
        if let textField = owner as? NSTextField {
            NotificationCenter.default.addObserver(self, selector: #selector(controlTextDidChange(_:)), name: NSControl.textDidChangeNotification, object: textField)
        }
    }

    @objc func controlTextDidChange(_ obj: Notification) {
        bindingActions.forEach { $0.invoke(obj.object) }
        actions.forEach { $0.invoke(obj.object) }
    }

    @objc func invokeAction(_ sender: Any?) {
        if let originTarget, let originAction {
            NSApplication.shared.sendAction(originAction, to: originTarget, from: sender)
        }
        bindingActions.forEach { $0.invoke(sender) }
        actions.forEach { $0.invoke(sender) }
    }

    @discardableResult
    func addAction(_ actionClosure: @escaping ActionClosure) -> ActionIdentifier {
        let action = Action(closure: actionClosure)
        actions.append(action)
        return action.id
    }

    func removeAction(for id: ActionIdentifier) {
        actions.remove(id: id)
    }

    func removeAllActions() {
        actions.removeAll()
    }

    @discardableResult
    func addBindingAction(_ bindingActionClosure: @escaping ActionClosure) -> ActionIdentifier {
        let bindingAction = Action(closure: bindingActionClosure)
        bindingActions.append(bindingAction)
        return bindingAction.id
    }

    func removeBindingAction(for id: ActionIdentifier) {
        bindingActions.remove(id: id)
    }

    func removeAllBindingActions() {
        bindingActions.removeAll()
    }
}

#endif
