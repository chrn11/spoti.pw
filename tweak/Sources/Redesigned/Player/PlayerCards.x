// Player redesign: nothing is kept under the player. Every card (about the artist, videos, SongDNA,
// events, explore, credits, merch, the lyrics card, anything Spotify adds later) reports no height, so
// the list closes up around it and the player is one screen; PlayerScroll.x closes off the gaps the
// list leaves between them, and the lyrics come to the player itself (PlayerLyrics.x) instead of
// waiting on a card below it.
//
// A block on everything rather than a list of what to drop: the server decides which cards a track
// gets, and a new kind should not turn up under a redesigned player. The collapse is the one
// Native/Player/PlayerDeclutter.x has shipped.
//
// Tree (trees/clean/player/01.txt:385, lyrics/01.txt:996-999): every card is an Element_List.CollectionViewCell
// whose first subview is an ElementContentView naming NowPlaying_ScrollAPI, then an ElementView, then
// the card's own root: CreatorBiographyCardLayout, song-dna-npv-card, Lyrics_CardElementImpl.CardView
// id=lyrics-card-view and so on (all ten player snapshots). The cells of lists inside a card
// (WatchFeed's) name WatchFeed_ComponentAPI instead, so they are left to their card.
#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRKit.h"
#import "Player.h"

// Whether the cell's content is the player's card list, remembered per content class.
static BOOL isPlayerCard(UIView *content) {
    static NSMutableSet<Class> *yes, *no;
    if (!yes) {
        yes = [NSMutableSet set];
        no = [NSMutableSet set];
    }
    Class cls = object_getClass(content);
    if (!cls || [no containsObject:cls]) return NO;
    if ([yes containsObject:cls]) return YES;
    BOOL player = [NSStringFromClass(cls) containsString:@"NowPlaying_ScrollAPI"];
    [(player ? yes : no) addObject:cls];
    return player;
}

static BOOL isLyricsCard(UIView *content) {
    return content && (SGHasClass(content, @"Lyrics_CardElementImpl")
                       || SGRFindByIdentifier(content, @"lyrics-card-view", NULL) != nil);
}

static char kLyricsHiddenKey;

static void setLyricsCardSuppressed(UICollectionViewCell *cell, BOOL suppressed) {
    UIView *content = cell.contentView.subviews.firstObject;
    if (!content) return;
    if (suppressed) {
        objc_setAssociatedObject(cell, &kLyricsHiddenKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        content.alpha = 0;
        content.userInteractionEnabled = NO;
        content.accessibilityElementsHidden = YES;
    } else if (objc_getAssociatedObject(cell, &kLyricsHiddenKey)) {
        objc_setAssociatedObject(cell, &kLyricsHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        content.alpha = 1;
        content.userInteractionEnabled = YES;
        content.accessibilityElementsHidden = NO;
    }
}

%hook _TtC12Element_List18CollectionViewCell
- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)attributes {
    UICollectionViewLayoutAttributes *result = %orig;
    UIView *cell = (UIView *)self;
    UIView *content = cell.subviews.firstObject;
    // The compatibility path deliberately avoids collapsing every self-sizing card on iOS 16/17,
    // but the native lyrics card must not coexist with PlayerLyrics.x's own overlay. This one card is
    // identified before changing its height and does not mutate its contentView constraints.
    if (SGRedesignUsesSafeLegacyLayout()) {
        if (content && isLyricsCard(content)) {
            setLyricsCardSuppressed((UICollectionViewCell *)self, YES);
            result.size = CGSizeMake(result.size.width, 0);
            cell.clipsToBounds = YES;
        } else {
            setLyricsCardSuppressed((UICollectionViewCell *)self, NO);
        }
        return result;
    }
    if (!content || !isPlayerCard(content)) return result;
    result.size = CGSizeMake(result.size.width, 0);
    cell.clipsToBounds = YES;

    static NSMutableSet<NSString *> *logged;
    if (!logged) logged = [NSMutableSet set];
    UIView *root = content.subviews.firstObject.subviews.firstObject;
    NSString *name = root ? NSStringFromClass(root.class) : @"nothing yet";
    if (![logged containsObject:name]) {
        [logged addObject:name];
        SGLog(@"redesign player: collapsed card root %@ (%lu kinds so far)", name, (unsigned long)logged.count);
    }
    return result;
}
- (void)layoutSubviews {
    %orig;
    if (SGRedesignUsesSafeLegacyLayout()) {
        UIView *content = ((UICollectionViewCell *)self).contentView.subviews.firstObject;
        if (content && isLyricsCard(content)) setLyricsCardSuppressed((UICollectionViewCell *)self, YES);
    }
}

- (void)prepareForReuse {
    %orig;
    setLyricsCardSuppressed((UICollectionViewCell *)self, NO);
}
%end

%ctor {
    if (!SGRedesignedUI()) return;
    %init;
    SGRequireClasses(@[@"_TtC12Element_List18CollectionViewCell"]);
}
