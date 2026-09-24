#import "Settings/SGModPage.h"
#import "AdBlock.h"

NSString *const SGFakePremiumWarning = @"This is the part of EeveeSpotify Spotify's takedown went after, and it has not been tested here. It can end in a forced logout or worse for the account. A Premium account gains nothing from it.";

// Every switch here forces a flag Spotify ships on to off, so the titles name the blocking: on stops
// the thing, off is Spotify's own value. Hide ads and Hide upsells already force the first two
// sections off, which locks those rows.
static UIViewController *adFlagsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Ad and upsell flags" intro:SGRestartNote sections:@[
        SGNotedSection(@"Ads", @[
            SGKillRow(@"Block the ad when the app opens", @"ios-feature-adonappopen.enabled"),
            SGKillRow(@"Block its CTA card", @"ios-feature-adonappopen.cta_card_enabled"),
        ], @"Locked while Hide ads is on."),
        SGNotedSection(@"Upsells", @[
            SGKillRow(@"Hide the shuffle toggle upsell", @"ios-feature-shuffletoggleupsell.is_enabled_pt2"),
            SGKillRow(@"Hide the shuffle upsell in the video player", @"ios-feature-nowplaying-modes.video_first_shuffle_upsell_enabled"),
        ], @"Locked while Hide upsells is on."),
    ] footer:nil];
}

// The switches first and what they have stopped last, so the counters bury no setting. The Search
// clutter switches and the telemetry counters live on the Privacy & clutter page.
UIViewController *SGAdsSettingsPage(void) {
    NSMutableArray<SGModRow *> *counts = [NSMutableArray array];
    for (NSString *label in SGAdBlockLabels()) {
        [counts addObject:SGStatRow(label, ^NSString *{
            return @(SGAdBlockCount(label)).stringValue;
        })];
    }
    [counts addObject:SGStatRow(@"Total", ^NSString *{
        return @(SGAdBlockCount(nil)).stringValue;
    })];
    [counts addObject:SGActionRow(@"Reset the counters", nil, ^{ SGResetAdBlock(); })];

    SGModRow *fakePremium = SGOptionRow(@"Spoof Premium", nil, SGKeyFakePremium);
    fakePremium.warning = SGFakePremiumWarning;

    return [[SGModPage alloc] initWithTitle:@"Premium, ads & privacy" intro:SGRestartNote sections:@[
        SGNotedSection(@"Ads", @[
            SGWithSymbol(SGOptionRow(@"Hide ads", nil, SGKeyHideAds), @"speaker.slash"),
            SGWithSymbol(SGOptionRow(@"Hide upsells", nil, SGKeyHideUpsells), @"hand.raised"),
            SGWithSymbol(SGPageRow(@"Ad and upsell flags", ^UIViewController *{ return adFlagsPage(); }), @"flag"),
        ], @"From EeveeSpotify, off until switched on. They reach only what is drawn; audio ads between songs are Spoof Premium's to stop."),
        SGNotedSection(@"Premium", @[
            SGWithSymbol(fakePremium, @"crown"),
        ], @"Free accounts only."),
        SGSection(@"Ads blocked so far", counts),
    ] footer:nil];
}
