import Foundation

@MainActor
public protocol NavigationContent: AnyObject {
    var onBeginNavigation: (() -> Void)? { set get }
    var onEndNavigation: (() -> Void)? { set get }
}

@MainActor
private var onBeginNavigationKeys = AssociatedKeys()

@MainActor
private var onEndNavigationKeys = AssociatedKeys()

struct AssociatedKeys {
    var keys: [AnyHashableMetatype: UnsafeMutableRawPointer] = [:]
    
    mutating func key<T>(of type: T.Type) -> UnsafeMutableRawPointer {
        let key = AnyHashableMetatype(type)
        if let associatedKey = keys[key] {
            return associatedKey
        } else {
            let associatedKey = malloc(1)!
            keys[key] = associatedKey
            return associatedKey
        }
    }
}


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
}

extension NavigationContent {

    public var onBeginNavigation: (() -> Void)? {
        set {
            objc_setAssociatedObject(self, onBeginNavigationKeys.key(of: Self.self), newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, onBeginNavigationKeys.key(of: Self.self)) as? () -> Void
        }
    }

    public var onEndNavigation: (() -> Void)? {
        set {
            objc_setAssociatedObject(self, onEndNavigationKeys.key(of: Self.self), newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, onEndNavigationKeys.key(of: Self.self)) as? () -> Void
        }
    }
}
