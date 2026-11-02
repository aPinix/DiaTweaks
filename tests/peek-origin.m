#import "Patches/Peek/Peek.h"

// Let Core Animation resolve the transform independently, then map its result back through AppKit.
static NSRect DPTransformedFrame(DPPeekCard *peek, CATransform3D transform, CGPoint anchor) {
    CALayer *parent = [CALayer layer], *layer = [CALayer layer];
    parent.bounds = peek.layer.bounds;
    parent.geometryFlipped = peek.layer.geometryFlipped;
    layer.bounds = peek.card.layer.bounds;
    layer.geometryFlipped = peek.card.layer.geometryFlipped;
    layer.anchorPoint = anchor;
    NSRect frame = [peek convertRectToLayer:peek.card.frame];
    layer.position = CGPointMake(NSMinX(frame) + anchor.x * NSWidth(frame),
        NSMinY(frame) + anchor.y * NSHeight(frame));
    [parent addSublayer:layer];
    layer.transform = transform;
    return [peek convertRectFromLayer:[layer convertRect:layer.bounds toLayer:parent]];
}

void DPTestPeekOpening(DPPeekCard *peek) {
    CAAnimationGroup *opening = (id)[peek.card.layer animationForKey:@"peek"];
    CABasicAnimation *growth = nil;
    for (CABasicAnimation *part in opening.animations) if ([part.keyPath isEqual:@"transform"]) growth = part;
    NSCAssert(growth.fromValue, @"opening has a spatial starting state");
    CATransform3D seed = [growth.fromValue CATransform3DValue];
    [peek.window displayIfNeeded];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    NSRect actual = DPTransformedFrame(peek, seed, peek.card.layer.anchorPoint), expected = peek.originFrame;
    NSCAssert(fabs(NSMidX(actual) - NSMidX(expected)) < 0.01 && fabs(NSMidY(actual) - NSMidY(expected)) < 0.01
        && fabs(NSWidth(actual) - NSWidth(expected)) < 0.01 && fabs(NSHeight(actual) - NSHeight(expected)) < 0.01,
        @"the original opening seed maps to the click after the first real display (actual=%@ expected=%@)",
        NSStringFromRect(actual), NSStringFromRect(expected));
    NSCAssert([peek.card.layer animationForKey:@"peek"], @"initial display preserves the opening animation");
}

void DPTestPeekOrigin(DPPeekCard *peek) {
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    NSCAssert(peek.card.layer.superlayer == peek.layer, @"check the rendered AppKit layer hierarchy");
    NSPoint saved = peek.clickPointInWindow;
    NSRect bounds = peek.bounds;
    NSArray<NSValue *> *points = @[
        [NSValue valueWithPoint:NSMakePoint(NSMinX(bounds) + 12, NSMinY(bounds) + 18)],
        [NSValue valueWithPoint:NSMakePoint(NSMaxX(bounds) - 12, NSMinY(bounds) + 18)],
        [NSValue valueWithPoint:NSMakePoint(NSMinX(bounds) + 12, NSMaxY(bounds) - 18)],
        [NSValue valueWithPoint:NSMakePoint(NSMaxX(bounds) - 12, NSMaxY(bounds) - 18)],
        [NSValue valueWithPoint:NSMakePoint(NSMidX(bounds), NSMidY(bounds))]];
    for (NSValue *value in points) {
        NSPoint point = value.pointValue;
        peek.clickPointInWindow = [peek convertPoint:point toView:nil];
        NSRect target = peek.originFrame;
        NSRect actual = DPTransformedFrame(peek, [peek transformToFrame:target], peek.card.layer.anchorPoint);
        NSCAssert(fabs(NSMidX(actual) - point.x) < 0.001 && fabs(NSMidY(actual) - point.y) < 0.001,
            @"the card starts at the clicked point in every corner, including flipped Y coordinates");
        NSCAssert(fabs(NSWidth(actual) / NSWidth(peek.card.frame) - 0.1) < 0.001
            && fabs(NSHeight(actual) / NSHeight(peek.card.frame) - 0.1) < 0.001, @"origin scaling preserves the page's aspect ratio");
        NSRect source = [peek convertRectToLayer:peek.card.frame], destination = [peek convertRectToLayer:target];
        for (NSNumber *component in @[@0, @0.5, @1]) {
            CGPoint anchor = CGPointMake(component.doubleValue, component.doubleValue);
            NSRect anchored = DPTransformedFrame(peek, DPPeekSqueeze(source, destination, anchor), anchor);
            NSCAssert(fabs(NSMidX(anchored) - point.x) < 0.001 && fabs(NSMidY(anchored) - point.y) < 0.001,
                @"origin transforms respect the backing layer's anchor");
        }
    }
    peek.clickPointInWindow = saved;
    NSPoint oldOrigin = peek.window.frame.origin;
    [peek.window setFrameOrigin:NSMakePoint(oldOrigin.x + 40, oldOrigin.y + 30)];
    NSPoint expected = [peek convertPoint:saved fromView:nil];
    NSCAssert(fabs(NSMidX(peek.originFrame) - expected.x) < 0.001
        && fabs(NSMidY(peek.originFrame) - expected.y) < 0.001, @"moving the window keeps the origin attached to its content");
    [peek.window setFrameOrigin:oldOrigin];
}
