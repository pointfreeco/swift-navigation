#if __has_include(<TargetConditionals.h>)
  #include <TargetConditionals.h>

  #if __has_include(<UIKit/UIKit.h>) && !TARGET_OS_WATCH
    @import ObjectiveC;
    @import UIKit;
    #import "shim.h"

    @interface Shim : NSObject

    @end

    @implementation Shim

    // NB: We must use Objective-C here to eagerly swizzle view controller code that is responsible
    //     for state-driven presentation and dismissal of child features.

    + (void)load {
      method_exchangeImplementations(
        class_getInstanceMethod(UIViewController.class, @selector(viewDidAppear:)),
        class_getInstanceMethod(UIViewController.class, @selector(UIKitNavigation_viewDidAppear:))
      );
      method_exchangeImplementations(
        class_getInstanceMethod(UIViewController.class, @selector(viewDidDisappear:)),
        class_getInstanceMethod(UIViewController.class, @selector(UIKitNavigation_viewDidDisappear:))
      );
    }

    @end

    static void *hasViewAppearedKey = &hasViewAppearedKey;
    static void *onDismissKey = &onDismissKey;
    static void *onViewAppearKey = &onViewAppearKey;

    @implementation UIViewController (UIKitNavigation)

    - (void)UIKitNavigation_viewDidAppear:(BOOL)animated {
      [self UIKitNavigation_viewDidAppear:animated];

      if (self.hasViewAppeared) {
        return;
      }
      self.hasViewAppeared = YES;
      for (void (^work)() in self.onViewAppear) {
        work();
      }
      self.onViewAppear = @[];
    }

    - (void)UIKitNavigation_viewDidDisappear:(BOOL)animated {
      [self UIKitNavigation_viewDidDisappear:animated];

      if ((self.isBeingDismissed || self.isMovingFromParentViewController) && self.onDismiss != NULL) {
        self.onDismiss();
        self.onDismiss = nil;
      }
    }

    - (BOOL)hasViewAppeared {
      return [objc_getAssociatedObject(self, hasViewAppearedKey) boolValue];
    }

    - (void)setHasViewAppeared:(BOOL)hasViewAppeared {
      objc_setAssociatedObject(
        self, hasViewAppearedKey, @(hasViewAppeared), OBJC_ASSOCIATION_COPY_NONATOMIC
      );
    }

    - (void (^)())onDismiss {
      return objc_getAssociatedObject(self, onDismissKey);
    }

    - (void)setOnDismiss:(void (^)())onDismiss {
      objc_setAssociatedObject(self, onDismissKey, [onDismiss copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    - (NSMutableArray<void (^)()> *)onViewAppear {
      id onViewAppear = objc_getAssociatedObject(self, onViewAppearKey);
      return onViewAppear == nil ? @[] : onViewAppear;
    }

    - (void)setOnViewAppear:(NSMutableArray<void (^)()> *)onViewAppear {
      objc_setAssociatedObject(self, onViewAppearKey, onViewAppear, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    @end
  #endif
#endif
