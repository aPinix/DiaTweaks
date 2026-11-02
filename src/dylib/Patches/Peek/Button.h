#import "Peek.h"

@interface DPPeekButton : NSButton
@property (strong) NSTrackingArea *hoverArea;
@property BOOL hovered;
@property (strong) CALayer *artwork;
@property (strong) CAShapeLayer *disc, *glyph;
- (void)updateAppearanceAnimated:(BOOL)animated;
@end

@interface DPPeekButton (Artwork)
- (void)layoutArtwork;
@end

CGPathRef DPPeekSymbolPath(NSInteger symbol, NSRect bounds) CF_RETURNS_RETAINED;
