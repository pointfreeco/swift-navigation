#if __has_include(<TargetConditionals.h>)
#include <TargetConditionals.h>

#if __has_include(<AppKit/AppKit.h>) && !TARGET_OS_MACCATALYST
@import ObjectiveC;
@import AppKit;
#import "shim.h"

@interface AppKitNavigationShim : NSObject

@end

@implementation AppKitNavigationShim

// NB: We must use Objective-C here to eagerly swizzle view controller code that is responsible
//     for state-driven presentation and dismissal of child features.

+ (void)load {
    method_exchangeImplementations(
        class_getInstanceMethod(NSViewController.class, @selector(viewDidAppear)),
        class_getInstanceMethod(NSViewController.class, @selector(AppKitNavigation_viewDidAppear))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSViewController.class, @selector(viewDidDisappear)),
        class_getInstanceMethod(NSViewController.class, @selector(AppKitNavigation_viewDidDisappear))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSViewController.class, @selector(dismissViewController:)),
        class_getInstanceMethod(NSViewController.class, @selector(AppKitNavigation_dismissViewController:))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSSavePanel.class, NSSelectorFromString(@"setFinalURL:")),
        class_getInstanceMethod(NSSavePanel.class, @selector(AppKitNavigation_setFinalURL:))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSSavePanel.class, NSSelectorFromString(@"setFinalURLs:")),
        class_getInstanceMethod(NSSavePanel.class, @selector(AppKitNavigation_setFinalURLs:))
        );
}

@end

static void *hasViewAppearedKey = &hasViewAppearedKey;
static void *isBeingDismissedKey = &isBeingDismissedKey;
static void *onDismissKey = &onDismissKey;
static void *onViewAppearKey = &onViewAppearKey;

@interface NSViewController (AppKitNavigationDismissal)

// NB: Set from 'dismissViewController:' on the controller being dismissed and consumed by its
//     next 'viewDidDisappear'. Prefixed like everything else this file adds to AppKit's classes, so
//     it cannot collide with a method AppKit adds later.
@property (setter=set_AppKitNavigation_isBeingDismissed:) BOOL _AppKitNavigation_isBeingDismissed;

@end

@implementation NSViewController (AppKitNavigationDismissal)

- (BOOL)_AppKitNavigation_isBeingDismissed {
    return [objc_getAssociatedObject(self, isBeingDismissedKey) boolValue];
}

- (void)set_AppKitNavigation_isBeingDismissed:(BOOL)isBeingDismissed {
    objc_setAssociatedObject(
        self, isBeingDismissedKey, @(isBeingDismissed), OBJC_ASSOCIATION_COPY_NONATOMIC
        );
}

@end

@implementation NSViewController (AppKitNavigation)

- (void)AppKitNavigation_viewDidAppear {
    [self AppKitNavigation_viewDidAppear];

    if (self._AppKitNavigation_hasViewAppeared) {
        return;
    }

    self._AppKitNavigation_hasViewAppeared = YES;

    for (void (^work)() in self._AppKitNavigation_onViewAppear) {
        work();
    }

    self._AppKitNavigation_onViewAppear = @[];
}

- (void)AppKitNavigation_viewDidDisappear {
    [self AppKitNavigation_viewDidDisappear];

    if (!self._AppKitNavigation_isBeingDismissed) {
        return;
    }
    self._AppKitNavigation_isBeingDismissed = NO;

    void (^onDismiss)(void) = self._AppKitNavigation_onDismiss;
    self._AppKitNavigation_onDismiss = nil;
    if (onDismiss != NULL) {
        onDismiss();
    }
}

- (void)AppKitNavigation_dismissViewController:(NSViewController *)viewController {
    // NB: The argument is the controller being dismissed; the receiver is its presenter (or the
    //     controller itself, when it dismisses itself). The flag belongs on the argument, and it
    //     has to be set before handing over, because a dismissal without animation reaches
    //     'viewDidDisappear' before the original implementation returns. Only a controller that is
    //     actually presented is marked, so a stray call cannot leave a flag behind for some later,
    //     unrelated disappearance to act on.
    if (viewController.presentingViewController != nil) {
        viewController._AppKitNavigation_isBeingDismissed = YES;
    }
    [self AppKitNavigation_dismissViewController:viewController];
}

- (BOOL)_AppKitNavigation_hasViewAppeared {
    return [objc_getAssociatedObject(self, hasViewAppearedKey) boolValue];
}

- (void)set_AppKitNavigation_hasViewAppeared:(BOOL)_AppKitNavigation_hasViewAppeared {
    objc_setAssociatedObject(
        self, hasViewAppearedKey, @(_AppKitNavigation_hasViewAppeared), OBJC_ASSOCIATION_COPY_NONATOMIC
        );
}

- (void (^)())_AppKitNavigation_onDismiss {
    return objc_getAssociatedObject(self, onDismissKey);
}

- (void)set_AppKitNavigation_onDismiss:(void (^)())_AppKitNavigation_onDismiss {
    objc_setAssociatedObject(self, onDismissKey, [_AppKitNavigation_onDismiss copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSMutableArray<void (^)()> *)_AppKitNavigation_onViewAppear {
    id onViewAppear = objc_getAssociatedObject(self, onViewAppearKey);

    return onViewAppear == nil ? @[] : onViewAppear;
}

- (void)set_AppKitNavigation_onViewAppear:(NSMutableArray<void (^)()> *)onViewAppear {
    objc_setAssociatedObject(self, onViewAppearKey, onViewAppear, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation NSSavePanel (AppKitNavigation)

- (void)setAppKitNavigation_onFinalURLs:(void (^)(NSArray<NSURL *> * _Nonnull))AppKitNavigation_onFinalURLs {
    objc_setAssociatedObject(self, @selector(AppKitNavigation_onFinalURLs), AppKitNavigation_onFinalURLs, OBJC_ASSOCIATION_COPY);
}

- (void (^)(NSArray<NSURL *> * _Nonnull))AppKitNavigation_onFinalURLs {
    return objc_getAssociatedObject(self, @selector(AppKitNavigation_onFinalURLs));
}

- (void)setAppKitNavigation_onFinalURL:(void (^)(NSURL * _Nullable))AppKitNavigation_onFinalURL {
    objc_setAssociatedObject(self, @selector(AppKitNavigation_onFinalURL), AppKitNavigation_onFinalURL, OBJC_ASSOCIATION_COPY);
}

- (void (^)(NSURL * _Nullable))AppKitNavigation_onFinalURL {
    return objc_getAssociatedObject(self, @selector(AppKitNavigation_onFinalURL));
}

- (void)AppKitNavigation_setFinalURL:(nullable NSURL *)url {
    [self AppKitNavigation_setFinalURL:url];
    if (self.AppKitNavigation_onFinalURL) {
        self.AppKitNavigation_onFinalURL(url);
    }
}

- (void)AppKitNavigation_setFinalURLs:(NSArray<NSURL *> *)urls {
    [self AppKitNavigation_setFinalURLs:urls];
    if (self.AppKitNavigation_onFinalURLs) {
        self.AppKitNavigation_onFinalURLs(urls);
    }
}

@end

#endif /* if __has_include(<AppKit/AppKit.h>) && !TARGET_OS_MACCATALYST */
#endif /* if __has_include(<TargetConditionals.h>) */
