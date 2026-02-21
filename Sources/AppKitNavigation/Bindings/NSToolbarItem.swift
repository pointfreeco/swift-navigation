#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSToolbarItem: @retroactive Sendable {}
extension NSToolbarItem: TargetActionProtocol {}

#endif
