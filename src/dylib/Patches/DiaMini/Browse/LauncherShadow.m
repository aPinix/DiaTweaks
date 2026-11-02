#import "Launcher.h"

@interface DPMiniShadowWindow : NSWindow
@end
@implementation DPMiniShadowWindow
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }
- (BOOL)isAccessibilityElement { return NO; }
- (NSRect)constrainFrameRect:(NSRect)frame toScreen:(NSScreen *)screen { return frame; }
@end

@implementation DPMiniLauncher (Shadow)
- (void)updateLauncherShadow {
    // A separate, noninteractive window lets the soft shadow extend beyond the search panel's bounds.
    CGFloat padding = 72;
    NSRect frame = NSInsetRect(self.window.frame, -padding, -padding);
    if (!self.shadowWindow) {
        NSWindow *shadow = [[DPMiniShadowWindow alloc] initWithContentRect:frame styleMask:NSWindowStyleMaskBorderless
            backing:NSBackingStoreBuffered defer:NO];
        shadow.title = @"Dia Mini Shadow"; shadow.identifier = @"DiaTweaks.MiniLauncherShadow";
        shadow.backgroundColor = NSColor.clearColor; shadow.opaque = NO; shadow.hasShadow = NO;
        shadow.ignoresMouseEvents = YES; shadow.releasedWhenClosed = NO; shadow.excludedFromWindowsMenu = YES;
        shadow.level = self.window.level; shadow.collectionBehavior = self.window.collectionBehavior;
        shadow.contentView.wantsLayer = YES;
        CALayer *halo = [CALayer layer]; halo.shadowColor = NSColor.blackColor.CGColor;
        halo.shadowOpacity = 0.4; halo.shadowRadius = 32; halo.shadowOffset = CGSizeMake(0, -10);
        [shadow.contentView.layer addSublayer:halo];
        self.shadowWindow = shadow;
        [self.window addChildWindow:shadow ordered:NSWindowBelow];
    }
    [self.shadowWindow setFrame:frame display:NO];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    NSRect bounds = self.shadowWindow.contentView.bounds, card = NSInsetRect(bounds, padding, padding);
    CALayer *halo = self.shadowWindow.contentView.layer.sublayers.firstObject;
    halo.frame = card;
    CGPathRef outline = CGPathCreateWithRoundedRect(halo.bounds, 18, 18, NULL);
    halo.shadowPath = outline; CGPathRelease(outline);
    // Keep the panel's translucent interior clear; only the exterior shadow is drawn.
    CAShapeLayer *mask = [CAShapeLayer layer]; mask.frame = bounds; mask.fillRule = kCAFillRuleEvenOdd;
    CGMutablePathRef path = CGPathCreateMutable(); CGPathAddRect(path, NULL, bounds);
    CGPathAddRoundedRect(path, NULL, card, 18, 18); mask.path = path; CGPathRelease(path);
    self.shadowWindow.contentView.layer.mask = mask;
    [CATransaction commit];
}
- (void)closeLauncherShadow {
    [self.window removeChildWindow:self.shadowWindow];
    [self.shadowWindow close]; self.shadowWindow = nil;
}
@end
