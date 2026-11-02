#import "Patches/Peek/Peek.h"

// Scale around the layer's anchor, translating between frames in its parent's coordinates.
CATransform3D DPPeekSqueeze(NSRect bounds, NSRect target, CGPoint anchor) {
    CATransform3D transform = CATransform3DMakeScale(NSWidth(target) / MAX(1, NSWidth(bounds)), NSHeight(target) / MAX(1, NSHeight(bounds)), 1);
    transform.m41 = NSMinX(target) - NSMinX(bounds) + anchor.x * (NSWidth(target) - NSWidth(bounds));
    transform.m42 = NSMinY(target) - NSMinY(bounds) + anchor.y * (NSHeight(target) - NSHeight(bounds));
    return transform;
}

@implementation DPPeekCard (Origin)
- (NSRect)originFrame {
    NSPoint point = [self convertPoint:self.clickPointInWindow fromView:nil];
    NSSize size = NSMakeSize(NSWidth(self.cardFrame) * 0.1, NSHeight(self.cardFrame) * 0.1);
    return NSMakeRect(point.x - size.width / 2, point.y - size.height / 2, size.width, size.height);
}

- (CATransform3D)transformToFrame:(NSRect)frame {
    // AppKit can flip the card's backing layer after display. Its parent stays in Peek's coordinates.
    NSRect source = [self convertRectToLayer:self.card.frame], target = [self convertRectToLayer:frame];
    return DPPeekSqueeze(source, target, self.card.layer.anchorPoint);
}
@end
