#import "SGUIMode.h"
#import "SGLog.h"
#import "SGPrefs.h"

// The redesign can run on the same floor as Spotify 9.1.78. iOS 26 adds Apple's native
// Liquid Glass implementation, but the Kit has a blur/solid compatibility renderer for older UIKit.
BOOL SGRedesignAvailable(void) {
    if (@available(iOS 16.1, *)) return YES;
    return NO;
}

// Whether UIKit can provide UIGlassEffect and the native Liquid Glass tab/navigation surfaces.
BOOL SGSystemGlassAvailable(void) {
    if (@available(iOS 26.0, *)) return YES;
    return NO;
}

// iOS 17's self-sizing implementation is the path known to re-enter while the redesign mutates a cell
// (issue #37). Spotify 9.1.78's iOS 16 floor does not need that conservative escape hatch, so keep the
// original section filtering there; iOS 17–25 retain Spotify's list geometry until a transactional filter
// is available. iOS 26 uses the original path with the system's tested UIKit.
BOOL SGRedesignUsesSafeLegacyLayout(void) {
    if (@available(iOS 26.0, *)) return NO;
    if (@available(iOS 17.0, *)) return YES;
    return NO;
}

BOOL SGRedesignedUI(void) {
    static BOOL on;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        on = SGRedesignedUIStored();
        SGLog(@"ui: %@%@", on ? @"redesigned" : @"native",
              SGSystemGlassAvailable() ? @"" : @" (compatibility glass/layout)");
    });
    return on;
}

BOOL SGNativeUI(void) {
    return !SGRedesignedUI();
}

BOOL SGRedesignedUIStored(void) {
    // The stored switch is left alone rather than turned off: a phone updated to iOS 26 gets the
    // redesign it was last asked for back.
    return SGRedesignAvailable() && SGFlag(SGKeyRedesign, NO);
}
