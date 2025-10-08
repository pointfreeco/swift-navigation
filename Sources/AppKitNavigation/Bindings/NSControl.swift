#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSControl: @retroactive Sendable {}
extension NSControl: TargetActionProtocol {}

extension NSControl {}

#endif
