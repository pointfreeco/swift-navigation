#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSMenuItem: TargetActionProtocol, @unchecked Sendable {}

#endif
