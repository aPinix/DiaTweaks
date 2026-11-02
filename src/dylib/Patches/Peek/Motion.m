#import "Patches/Peek/Peek.h"

static const CFTimeInterval DPPeekGrow = 0.20, DPPeekShrink = 0.22;
static CAMediaTimingFunction *DPPeekEase(void) { return [CAMediaTimingFunction functionWithControlPoints:0.2 :0.9 :0.25 :1]; }
CAMediaTimingFunction *DPPeekClosingEase(void) { return [CAMediaTimingFunction functionWithControlPoints:0.4 :0 :0.2 :1]; }

// A dismissal before the first display tick starts at the opening animation's seed, not the full-size model.
static void DPDisplayedState(CALayer *layer, CATransform3D *transform, float *opacity) {
    CALayer *shown = layer.presentationLayer;
    *transform = (shown ?: layer).transform; *opacity = (shown ?: layer).opacity;
    if (shown) return;
    CAAnimation *active = [layer animationForKey:@"peek"];
    NSArray *parts = [active isKindOfClass:CAAnimationGroup.class] ? ((CAAnimationGroup *)active).animations : active ? @[active] : @[];
    for (CABasicAnimation *part in parts) {
        if (![part isKindOfClass:CABasicAnimation.class] || !part.fromValue) continue;
        if ([part.keyPath isEqual:@"transform"]) *transform = [part.fromValue CATransform3DValue];
        if ([part.keyPath isEqual:@"opacity"]) *opacity = [part.fromValue floatValue];
    }
}

@implementation DPPeekCard (Motion)
- (void)animateIn {
    NSUInteger version = ++self.motionVersion;
    BOOL reduce = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    CFTimeInterval duration = reduce ? 0.08 : DPPeekGrow;
    NSMutableArray *animations = [NSMutableArray new];
    if (!reduce) {
        CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"transform"];
        grow.fromValue = [NSValue valueWithCATransform3D:[self transformToFrame:self.originFrame]];
        grow.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        grow.duration = duration;
        [animations addObject:grow];
    }
    CABasicAnimation *appear = [CABasicAnimation animationWithKeyPath:@"opacity"];
    appear.fromValue = @0; appear.toValue = @1; appear.duration = duration * 0.6;
    [animations addObject:appear];
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = animations; group.duration = duration; group.timingFunction = DPPeekEase();
    [self.card.layer addAnimation:group forKey:@"peek"];
    [self animateBackdrop:YES duration:duration];
    self.controls.alphaValue = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.closing || version != self.motionVersion) return;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.10; self.controls.animator.alphaValue = 1;
        }];
    });
}

- (void)animateOut:(void (^)(void))completion {
    NSUInteger version = ++self.motionVersion;
    BOOL reduce = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    CFTimeInterval duration = reduce ? 0.08 : DPPeekShrink;
    CATransform3D current; float opacity;
    DPDisplayedState(self.card.layer, &current, &opacity);
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{ if (version == self.motionVersion) completion(); }];
    NSMutableArray *animations = [NSMutableArray new];
    if (!reduce) {
        CABasicAnimation *shrink = [CABasicAnimation animationWithKeyPath:@"transform"];
        shrink.fromValue = [NSValue valueWithCATransform3D:current];
        shrink.toValue = [NSValue valueWithCATransform3D:[self transformToFrame:self.originFrame]];
        shrink.duration = duration;
        [animations addObject:shrink];
    }
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(opacity); fade.toValue = @0; fade.duration = duration; [animations addObject:fade];
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = animations; group.duration = duration; group.timingFunction = DPPeekClosingEase();
    group.fillMode = kCAFillModeForwards; group.removedOnCompletion = NO;
    [self.card.layer addAnimation:group forKey:@"peek"];
    [self animateBackdrop:NO duration:duration];
    [CATransaction commit];
}
@end
