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
}

@end

static void *hasViewAppearedKey = &hasViewAppearedKey;
static void *onDismissKey = &onDismissKey;
static void *onViewAppearKey = &onViewAppearKey;

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

- (void)setBeingDismissed:(BOOL)beingDismissed {
    objc_setAssociatedObject(self, @selector(isBeingDismissed), @(beingDismissed), OBJC_ASSOCIATION_COPY);
}

- (BOOL)isBeingDismissed {
    return [objc_getAssociatedObject(self, @selector(isBeingDismissed)) boolValue];
}

- (void)AppKitNavigation_viewDidDisappear {
    [self AppKitNavigation_viewDidDisappear];

    if ((self.isBeingDismissed) && self._AppKitNavigation_onDismiss != NULL) {
        self._AppKitNavigation_onDismiss();
        self._AppKitNavigation_onDismiss = nil;
        [self setBeingDismissed:NO];
    }
}

- (void)AppKitNavigation_dismissViewController:(NSViewController *)sender {
    [self AppKitNavigation_dismissViewController:sender];
    [self setBeingDismissed:YES];
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
#endif /* if __has_include(<AppKit/AppKit.h>) && !TARGET_OS_MACCATALYST */
#endif /* if __has_include(<TargetConditionals.h>) */
