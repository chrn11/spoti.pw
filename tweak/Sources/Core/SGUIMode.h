// Which of the two looks runs: Spotify's own screens with the mod's tweaks on them (Native/), or the
// redesign (Redesigned/), picked by Redesigned UI in Appearance. What does not draw on Spotify's
// screens (Shared/) runs under both. The switch is read once, the first time anything asks, so the
// hooks, the flags and the pages see one answer for the whole launch and a change waits for the restart.
//
// Every hook file of Native/ starts its %ctor with `if (!SGNativeUI()) return;`, every one of
// Redesigned/ with `if (!SGRedesignedUI()) return;`: the two never run together, which is what lets
// each hook the same Spotify class in its own way.
// Threading: safe from any thread.
#import <Foundation/Foundation.h>

#define SGKeyRedesign @"spotifyglass.redesign"

// The redesign is available on Spotify 9.1.78's iOS floor. This is separate from whether the system
// provides native UIGlassEffect.
BOOL SGRedesignAvailable(void);

// The system implementation is optional. On iOS 26+ Spotify/UIKit can provide UIGlassEffect and the
// native Liquid Glass surfaces; older supported systems use the Kit's blur/solid compatibility renderer.
BOOL SGSystemGlassAvailable(void);

// The redesigned screens are still available on Spotify 9.1.78's iOS floor, but the section-filtering
// hooks mutate self-sizing UICollectionView cells. iOS 16/17 need the conservative path until those
// mutations are made transactional; visual restyling and the rest of the redesign remain enabled.
BOOL SGRedesignUsesSafeLegacyLayout(void);

BOOL SGRedesignedUI(void);
BOOL SGNativeUI(void);
// The stored switch rather than the launch's, for settings pages opened after it was flipped: they
// show what the restart will bring.
BOOL SGRedesignedUIStored(void);
