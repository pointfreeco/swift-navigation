import Foundation

@MainActor
@objc
public protocol NavigationContent where Self: NSObject {
    var onBeginNavigation: (() -> Void)? { set get }
    var onEndNavigation: (() -> Void)? { set get }
}

@MainActor
private var onBeginNavigationKeys: [AnyHashableMetatype: UnsafeMutableRawPointer] = [:]

@MainActor
private var onEndNavigationKeys: [AnyHashableMetatype: UnsafeMutableRawPointer] = [:]
/// Hashable wrapper for any metatype value.
struct AnyHashableMetatype: Hashable {
    static func == (lhs: AnyHashableMetatype, rhs: AnyHashableMetatype) -> Bool {
        return lhs.base == rhs.base
    }

    let base: Any.Type

    init(_ base: Any.Type) {
        self.base = base
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(base))
    }
    // Pre Swift 4.2:
    // var hashValue: Int { return ObjectIdentifier(base).hashValue }
}

extension NavigationContent {
    static var onBeginNavigationKey: UnsafeMutableRawPointer {
        let key = AnyHashableMetatype(Self.self)
        if let onBeginNavigationKey = onBeginNavigationKeys[key] {
            return onBeginNavigationKey
        } else {
            let onBeginNavigationKey = malloc(1)!
            onBeginNavigationKeys[key] = onBeginNavigationKey
            return onBeginNavigationKey
        }
    }

    static var onEndNavigationKey: UnsafeMutableRawPointer {
        let key = AnyHashableMetatype(Self.self)
        if let onEndNavigationKey = onEndNavigationKeys[key] {
            return onEndNavigationKey
        } else {
            let onEndNavigationKey = malloc(1)!
            onEndNavigationKeys[key] = onEndNavigationKey
            return onEndNavigationKey
        }
    }

    var _onBeginNavigation: (() -> Void)? {
        set {
            objc_setAssociatedObject(self, Self.onBeginNavigationKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, Self.onBeginNavigationKey) as? () -> Void
        }
    }

    var _onEndNavigation: (() -> Void)? {
        set {
            objc_setAssociatedObject(self, Self.onEndNavigationKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, Self.onEndNavigationKey) as? () -> Void
        }
    }
}

@MainActor
protocol NavigatedProtocol: AnyObject {
    associatedtype Content: NavigationContent
    var content: Content? { get }
    var id: AnyHashable? { get }
    init(_ content: Content, id: AnyHashable?)
}
