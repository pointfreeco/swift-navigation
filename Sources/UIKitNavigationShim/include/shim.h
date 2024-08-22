#if __has_include(<TargetConditionals.h>)
  #include <TargetConditionals.h>

  #if __has_include(<UIKit/UIKit.h>) && !TARGET_OS_WATCH
    @import UIKit;

    NS_ASSUME_NONNULL_BEGIN

    @interface UIViewController (UIKitNavigation)

    @property BOOL _UIKitNavigation_hasViewAppeared;
    @property (nullable) void (^_UIKitNavigation_onDismiss)();
    @property NSArray<void(^)()> *_UIKitNavigation_onViewAppear;

    @end

    NS_ASSUME_NONNULL_END
  #endif
#endif
