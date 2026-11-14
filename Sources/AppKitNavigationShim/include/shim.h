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

@interface NSSavePanel (AppKitNavigation)
@property (nullable) void (^ AppKitNavigation_onFinalURL)(NSURL *_Nullable);
@property (nullable) void (^ AppKitNavigation_onFinalURLs)(NSArray<NSURL *> *);
@end

// MARK: - Multiple target-action pairs

// NB: AppKit has stored several target-action pairs per control since macOS 11, but only published
//     the API in the macOS 27 SDK. Redeclaring it here lets the binding layer register additional
//     actions without taking over a control's single 'target' / 'action' pair, while still building
//     against an older SDK. The whole block compiles away once the SDK in use declares it, so
//     nothing has to be deleted by hand — but the redeclaration should be dropped altogether once
//     the macOS 27 SDK is the minimum supported one.
//
//     Note that the events themselves are not all as old as the API: on macOS 26 a button click
//     only delivers NSControlEventTrackingBegan and NSControlEventTrackingEndedInside, and
//     NSControlEventValueChanged / NSControlEventPrimaryActionTriggered are never sent. Anything
//     relying on those has to stay behind an availability check.
//
//     The SDK spells the type 'NS_SWIFT_NAME(NSControl.Events)'. That must NOT be repeated here:
//     nesting a type inside a class that belongs to a *different* module makes the Swift importer
//     drop the whole declaration, taking the two methods with it, and Swift then sees neither
//     'NSControlEvents' nor 'NSControl.Events'. Without the attribute Swift imports the type under
//     its Objective-C name and the methods as 'addTarget(_:action:for:)'.
#if !defined(MAC_OS_VERSION_27_0) || __MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_VERSION_27_0

typedef NS_OPTIONS(NSUInteger, NSControlEvents) {
    NSControlEventTrackingBegan            = 1 <<  0,
    NSControlEventTrackingRepeated         API_AVAILABLE(macos(27.0)) = 1 <<  1,
    NSControlEventTrackingInside           = 1 <<  2,
    NSControlEventTrackingOutside          = 1 <<  3,
    NSControlEventTrackingEntered          = 1 <<  4,
    NSControlEventTrackingExited           = 1 <<  5,
    NSControlEventTrackingEndedInside      = 1 <<  6,
    NSControlEventTrackingEndedOutside     = 1 <<  7,
    NSControlEventTrackingCancelled        = 1 <<  8,

    NSControlEventValueChanged             API_AVAILABLE(macos(27.0)) = 1 << 12,
    NSControlEventPrimaryActionTriggered   API_AVAILABLE(macos(27.0)) = 1 << 13,
    NSControlEventMenuActionTriggered      API_AVAILABLE(macos(27.0)) = 1 << 14,

    NSControlEventAllTrackingEvents        = 0x00000FFF,
    NSControlEventApplicationReserved      API_AVAILABLE(macos(27.0)) = 0x0F000000,
    NSControlEventSystemReserved           = 0xF0000000,
    NSControlEventAllEvents                = 0xFFFFFFFF
} API_AVAILABLE(macos(11.0));

@interface NSControl (AppKitNavigationControlEvents)

/// Associates a target object and action method with one or more control events.
///
/// Unlike the 'target' and 'action' properties, this may be called several times to register
/// several pairs. The control does not retain the target.
- (void)addTarget:(nullable id)target
           action:(SEL)action
 forControlEvents:(NSControlEvents)controlEvents API_AVAILABLE(macos(11.0));

/// Stops the delivery of the specified events to the given target object.
///
/// Pass 'nil' as the action to remove all actions for the target.
- (void)removeTarget:(nullable id)target
              action:(nullable SEL)action
    forControlEvents:(NSControlEvents)controlEvents API_AVAILABLE(macos(11.0));

@end

#endif /* macOS 27 SDK redeclaration */

NS_ASSUME_NONNULL_END
#endif
#endif /* if __has_include(<TargetConditionals.h>) */
