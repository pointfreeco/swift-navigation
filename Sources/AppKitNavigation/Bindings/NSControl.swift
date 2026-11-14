#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSControl: @unchecked @retroactive Sendable {}
extension NSControl: TargetActionProtocol {}

extension NSControl {}

#endif
