#import "Patches/Peek/Button.h"

@implementation DPPeekButton
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)wantsUpdateLayer { return YES; }
- (void)updateLayer { [self updateAppearanceAnimated:NO]; }
- (void)drawRect:(NSRect)dirtyRect {} // The cell's bezel and image are replaced by vector layers.
- (void)layout { [super layout]; [self layoutArtwork]; }
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self layoutArtwork]; }
- (void)viewDidChangeBackingProperties { [super viewDidChangeBackingProperties]; [self layoutArtwork]; }
- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (self.hoverArea) [self removeTrackingArea:self.hoverArea];
    self.hoverArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
        options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:self.hoverArea];
}
- (void)mouseEntered:(NSEvent *)event { self.hovered = YES; [self updateAppearanceAnimated:YES]; }
- (void)mouseExited:(NSEvent *)event { self.hovered = NO; [self updateAppearanceAnimated:YES]; }
- (void)highlight:(BOOL)flag { [super highlight:flag]; [self updateAppearanceAnimated:YES]; }
- (void)updateAppearanceAnimated:(BOOL)animated {
    [self layoutArtwork];
    CALayer *layer = self.artwork, *shown = layer.presentationLayer ?: layer;
    CAShapeLayer *disc = self.disc, *shownDisc = (id)(disc.presentationLayer ?: disc);
    BOOL reduce = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    CGFloat scale = reduce ? 1 : self.isHighlighted ? 0.93 : self.hovered ? 1.06 : 1;
    CATransform3D transform = CATransform3DMakeScale(scale, scale, 1);
    CGColorRef color = [NSColor colorWithWhite:0 alpha:self.isHighlighted ? 0.96 : self.hovered ? 0.92 : 0.82].CGColor;
    CABasicAnimation *size = [CABasicAnimation animationWithKeyPath:@"transform"];
    size.fromValue = [NSValue valueWithCATransform3D:shown.transform];
    size.toValue = [NSValue valueWithCATransform3D:transform];
    CABasicAnimation *fill = [CABasicAnimation animationWithKeyPath:@"fillColor"];
    fill.fromValue = (__bridge id)shownDisc.fillColor; fill.toValue = (__bridge id)color;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    layer.transform = transform; disc.fillColor = color;
    [CATransaction commit];
    if (!animated) return;
    CFTimeInterval duration = self.isHighlighted ? 0.08 : self.hovered ? 0.12 : 0.18;
    for (CABasicAnimation *animation in @[size, fill]) {
        animation.duration = duration;
        animation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2 :0.8 :0.2 :1];
    }
    if (!reduce) [layer addAnimation:size forKey:@"peekHoverTransform"];
    else [layer removeAnimationForKey:@"peekHoverTransform"];
    [disc addAnimation:fill forKey:@"peekHoverColor"];
}
@end
