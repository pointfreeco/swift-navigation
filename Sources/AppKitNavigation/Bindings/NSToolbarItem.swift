#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSToolbarItem: @unchecked @retroactive Sendable {}
extension NSToolbarItem: TargetActionProtocol {}

#endif
