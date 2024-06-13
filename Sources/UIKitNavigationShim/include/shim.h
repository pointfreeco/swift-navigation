#if __has_include(<UIKit/UIKit.h>)
  @import UIKit;

  NS_ASSUME_NONNULL_BEGIN

  @interface UIViewController (UIKitNavigation)

  @property BOOL hasViewAppeared;
  @property (nullable) void (^onDismiss)();
  @property NSArray<void(^)()> *onViewAppear;

  @end

  NS_ASSUME_NONNULL_END
#endif
