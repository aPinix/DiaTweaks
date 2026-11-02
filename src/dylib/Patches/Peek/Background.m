#import "Patches/Peek/Peek.h"

CATransform3D DPPeekDepth(NSRect bounds, CGFloat scale) {
    CATransform3D transform = CATransform3DMakeScale(scale, scale, 1);
    transform.m41 = NSMidX(bounds) * (1 - scale);
    transform.m42 = NSMidY(bounds) * (1 - scale);
    return transform;
}

@implementation DPPeekCard (Background)
- (void)animateBackdrop:(BOOL)inward duration:(CFTimeInterval)duration {
    if (!self.pane || NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion) {
        [self restoreBackdrop]; return;
    }
    if (!self.backdropLayer) {
        self.backgroundWantsLayer = self.pane.wantsLayer;
        self.pane.wantsLayer = YES;
        self.backdropLayer = self.pane.layer;
    }
    CALayer *layer = self.backdropLayer;
    CATransform3D base = layer.transform;
    CATransform3D target = inward ? CATransform3DConcat(base, DPPeekDepth(layer.bounds, 0.975)) : base;
    CABasicAnimation *depth = [CABasicAnimation animationWithKeyPath:@"transform"];
    depth.fromValue = [NSValue valueWithCATransform3D:layer.presentationLayer ? layer.presentationLayer.transform : base];
    depth.toValue = [NSValue valueWithCATransform3D:target];
    depth.duration = duration;
    depth.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2 :0.9 :0.25 :1];
    depth.fillMode = kCAFillModeForwards;
    depth.removedOnCompletion = NO;
    [layer addAnimation:depth forKey:@"DiaTweaks.Peek.Depth"];
}
- (void)restoreBackdrop {
    [self.backdropLayer removeAnimationForKey:@"DiaTweaks.Peek.Depth"];
    if (self.backdropLayer && !self.backgroundWantsLayer && self.pane.layer == self.backdropLayer) self.pane.wantsLayer = NO;
    self.backdropLayer = nil;
}
@end
