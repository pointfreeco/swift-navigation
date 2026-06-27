#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import Foundation

@MainActor
protocol NavigationContent: AnyObject {
  var onBeginNavigation: (() -> Void)? { set get }
  var onEndNavigation: (() -> Void)? { set get }
}

@MainActor
private var onBeginNavigationKeys = AssociatedKeys()

@MainActor
private var onEndNavigationKeys = AssociatedKeys()

extension NavigationContent {
  var onBeginNavigation: (() -> Void)? {
    set {
      objc_setAssociatedObject(self, onBeginNavigationKeys.key(of: Self.self), newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    get {
      objc_getAssociatedObject(self, onBeginNavigationKeys.key(of: Self.self)) as? () -> Void
    }
  }

  var onEndNavigation: (() -> Void)? {
    set {
      objc_setAssociatedObject(self, onEndNavigationKeys.key(of: Self.self), newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    get {
      objc_getAssociatedObject(self, onEndNavigationKeys.key(of: Self.self)) as? () -> Void
    }
  }
}

#endif
