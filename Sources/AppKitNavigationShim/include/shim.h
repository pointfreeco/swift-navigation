#if __has_include(<TargetConditionals.h>)
  #include <TargetConditionals.h>

  #if __has_include(<AppKit/AppKit.h>) && !TARGET_OS_MACCATALYST
    @import AppKit;

    NS_ASSUME_NONNULL_BEGIN

    @interface NSViewController (AppKitNavigation)

    @property BOOL hasViewAppeared;
    @property (nullable) void (^onDismiss)();
    @property NSArray<void(^)()> *onViewAppear;

    @end

    NS_ASSUME_NONNULL_END
  #endif
#endif
