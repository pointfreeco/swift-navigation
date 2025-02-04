#if __has_include(<TargetConditionals.h>)
#include <TargetConditionals.h>

#if __has_include(<AppKit/AppKit.h>) && !TARGET_OS_MACCATALYST
@import AppKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSViewController (AppKitNavigation)

@property BOOL _AppKitNavigation_hasViewAppeared;
@property (nullable) void (^ _AppKitNavigation_onDismiss)();
@property NSArray<void (^)()> *_AppKitNavigation_onViewAppear;

@end

NS_ASSUME_NONNULL_END
#endif
#endif /* if __has_include(<TargetConditionals.h>) */
