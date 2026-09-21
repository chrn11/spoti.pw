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

// The section-filtering hooks mutate self-sizing UICollectionView cells. They are reliable on the
// iOS 26 path, but iOS 16/17 can re-enter preferredLayoutAttributesFittingAttributes: while those
// mutations are settling and eventually trip the scene-update watchdog. Older systems keep the
// Redesigned styling and use Spotify's own list sizing until that path is made fully transactional.
BOOL SGRedesignUsesSafeLegacyLayout(void) {
    return !SGSystemGlassAvailable();
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
