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
        class_getInstanceMethod(NSSavePanel.class, NSSelectorFromString(@"setFinalURL:")),
        class_getInstanceMethod(NSSavePanel.class, @selector(AppKitNavigation_setFinalURL:))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSSavePanel.class, NSSelectorFromString(@"setFinalURLs:")),
        class_getInstanceMethod(NSSavePanel.class, @selector(AppKitNavigation_setFinalURLs:))
        );
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
