#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
public protocol ModalSessionContent: ModalContent {
    func appKitNavigationBeginModalSession() -> NSApplication.ModalSession
}

extension NSWindow: ModalSessionContent {

    public func appKitNavigationBeginModalSession() -> NSApplication.ModalSession {
        __appKitNavigationBeginModalSession()
    }
    
    @objc func __appKitNavigationBeginModalSession() -> NSApplication.ModalSession {
        let modalSession = NSApplication.shared.beginModalSession(for: self)
//        NSApplication.shared.runModalSession(modalSession)
        return modalSession
    }
}

//extension NSSavePanel {
//    override func __appKitNavigationBeginModalSession() -> NSApplication.ModalSession {
//        begin
//    }
//}

#endif
