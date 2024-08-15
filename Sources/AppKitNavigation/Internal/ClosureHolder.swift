#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import Foundation

internal class ClosureHolder: NSObject {
    let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    func invoke() {
        closure()
    }
}

#endif
