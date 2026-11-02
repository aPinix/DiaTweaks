#import "Patches/Peek/Peek.h"

CATransform3D DPPeekDepth(NSRect bounds, CGFloat scale) {
    CATransform3D transform = CATransform3DMakeScale(scale, scale, 1);
    transform.m41 = NSMidX(bounds) * (1 - scale);
    transform.m42 = NSMidY(bounds) * (1 - scale);
    return transform;
}

@implementation DPPeekCard (Background)
- (void)animateBackdrop:(BOOL)inward duration:(CFTimeInterval)duration {
    if (!self.surface) { [self restoreBackdrop]; return; }
    BOOL reduce = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    if (!self.backdropLayer) {
        self.backgroundWantsLayer = self.surface.wantsLayer;
        self.surface.wantsLayer = YES;
        self.backdropLayer = self.surface.layer;
    }
    CALayer *layer = self.backdropLayer;
    CATransform3D base = layer.transform;
    CATransform3D target = inward && !reduce ? CATransform3DConcat(base, DPPeekDepth(layer.bounds, 0.975)) : base;
    CABasicAnimation *depth = [CABasicAnimation animationWithKeyPath:@"transform"];
    depth.fromValue = [NSValue valueWithCATransform3D:layer.presentationLayer ? layer.presentationLayer.transform : base];
    depth.toValue = [NSValue valueWithCATransform3D:target];
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @((layer.presentationLayer ?: layer).opacity);
    fade.toValue = @(layer.opacity * (inward ? 0.2 : 1));
    depth.duration = fade.duration = duration;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = reduce ? @[fade] : @[depth, fade]; group.duration = duration;
    group.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2 :0.9 :0.25 :1];
    group.fillMode = kCAFillModeForwards; group.removedOnCompletion = NO;
    [layer addAnimation:group forKey:@"DiaTweaks.Peek.Depth"];
}
- (void)restoreBackdrop {
    [self.backdropLayer removeAnimationForKey:@"DiaTweaks.Peek.Depth"];
    if (self.backdropLayer && !self.backgroundWantsLayer && self.surface.layer == self.backdropLayer) self.surface.wantsLayer = NO;
    self.backdropLayer = nil;
}
@end
