#import "Patches/Peek/Button.h"

@implementation DPPeekButton (Artwork)
- (void)layoutArtwork {
    if (!self.layer) return;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
    self.layer.masksToBounds = NO;
    if (!self.artwork) {
        self.artwork = [CALayer layer];
        self.artwork.anchorPoint = CGPointMake(0.5, 0.5);
        self.disc = [CAShapeLayer layer]; self.glyph = [CAShapeLayer layer];
        [self.artwork addSublayer:self.disc]; [self.artwork addSublayer:self.glyph];
        [self.layer addSublayer:self.artwork];
    }
    self.artwork.bounds = self.bounds;
    self.artwork.position = CGPointMake(NSMidX(self.bounds), NSMidY(self.bounds));
    self.disc.frame = self.glyph.frame = self.bounds;
    CGFloat scale = self.window ? self.window.backingScaleFactor : NSScreen.mainScreen.backingScaleFactor;
    self.artwork.contentsScale = self.disc.contentsScale = self.glyph.contentsScale = MAX(1, scale);
    // A 34-point circle inside a 40-point hit target leaves room even at the largest hover scale.
    CGPathRef circle = CGPathCreateWithEllipseInRect(NSInsetRect(self.bounds, 3, 3), NULL);
    self.disc.path = circle; CGPathRelease(circle);
    CGPathRef symbol = DPPeekSymbolPath(self.tag, self.bounds);
    self.glyph.path = symbol; CGPathRelease(symbol);
    self.glyph.fillColor = NSColor.clearColor.CGColor;
    self.glyph.strokeColor = NSColor.whiteColor.CGColor;
    self.glyph.lineWidth = 1.6;
    self.glyph.lineCap = kCALineCapRound; self.glyph.lineJoin = kCALineJoinRound;
    [CATransaction commit];
}
@end
