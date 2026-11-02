#import "Patches/Peek/Peek.h"

@implementation DPPeekCard (Expand)
- (void)animateExpand:(NSInteger)exit completion:(void (^)(void))completion {
    NSUInteger version = ++self.motionVersion;
    BOOL reduce = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    CFTimeInterval duration = reduce ? 0.08 : 0.26;
    NSRect target = self.bounds;
    if (exit == 2) { target.origin.x += target.size.width / 2; target.size.width /= 2; }
    CALayer *layer = self.card.layer, *shown = layer.presentationLayer ?: layer;
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{ if (version == self.motionVersion) completion(); }];
    CABasicAnimation *expand = [CABasicAnimation animationWithKeyPath:reduce ? @"opacity" : @"transform"];
    expand.fromValue = reduce ? @(shown.opacity) : [NSValue valueWithCATransform3D:shown.transform];
    expand.toValue = reduce ? @0 : [NSValue valueWithCATransform3D:DPPeekSqueeze(self.cardFrame, target)];
    expand.duration = duration;
    expand.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2 :0.9 :0.25 :1];
    expand.fillMode = kCAFillModeForwards; expand.removedOnCompletion = NO;
    [layer addAnimation:expand forKey:@"peek"];
    CABasicAnimation *corners = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    corners.fromValue = @((self.clip.layer.presentationLayer ?: self.clip.layer).cornerRadius);
    corners.toValue = @(exit == 2 ? 10 : self.pane.layer.cornerRadius);
    corners.duration = duration; corners.fillMode = kCAFillModeForwards; corners.removedOnCompletion = NO;
    [self.clip.layer addAnimation:corners forKey:@"peekCorners"];
    CABasicAnimation *clear = [CABasicAnimation animationWithKeyPath:@"opacity"];
    clear.fromValue = @((self.blur.layer.presentationLayer ?: self.blur.layer).opacity);
    clear.toValue = @0; clear.duration = duration;
    clear.fillMode = kCAFillModeForwards; clear.removedOnCompletion = NO;
    [self.blur.layer addAnimation:clear forKey:@"peek"];
    [self animateBackdrop:NO duration:duration];
    [CATransaction commit];
}
@end
