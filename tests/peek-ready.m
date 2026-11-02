#import "Patches/Peek/Peek.h"

@interface DPReadyPeekPage : NSObject <DPPeekPage>
@property (getter=isReadyToDisplay) BOOL ready;
@property (strong) NSURL *url;
@property (strong) NSView *host;
@property BOOL closed;
@end
@implementation DPReadyPeekPage
- (NSView *)createPaneHostView { self.host = [NSView new]; self.host.wantsLayer = YES; return self.host; }
- (void)attachToPaneHostView:(NSView *)host {}
- (void)detachFromPaneHostView:(NSView *)host {}
- (void)close { self.closed = YES; }
@end

static void DPReadyDrain(NSTimeInterval duration) {
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];
}
void DPTestPeekReady(NSWindow *window) {
    DPReadyPeekPage *page = [DPReadyPeekPage new];
    NSPoint point = [window convertPointToScreen:NSMakePoint(325, 480)];
    DPPeekCard *peek = DPPeekShowCard(window, page, point);
    CAAnimationGroup *opening = (id)[peek.card.layer animationForKey:@"peek"];
    NSCAssert(opening && opening.duration >= 0.18 && peek.card.alphaValue == 1 && peek.contentTimer,
        @"Peek starts growing synchronously, without a URL, paint or network response");
    NSCAssert(peek.loadingCanvas.superview == peek.clip && NSEqualRects(peek.loadingCanvas.frame, peek.clip.bounds)
        && [peek.clip.subviews indexOfObject:peek.loadingCanvas] < [peek.clip.subviews indexOfObject:peek.host]
        && peek.host.alphaValue == 1 && CGColorGetAlpha(peek.clip.layer.backgroundColor) == 0,
        @"the temporary canvas gives growth visible pixels without hiding Chromium or adding a permanent backing edge");
    CABasicAnimation *grow = (id)opening.animations.firstObject;
    NSCAssert([grow.keyPath isEqual:@"transform"]
        && CATransform3DEqualToTransform([grow.fromValue CATransform3DValue], [peek transformToFrame:peek.originFrame]),
        @"the immediate opening still grows from the original click");
    NSUInteger version = peek.motionVersion;
    DPReadyDrain(0.35); // Loading can outlast the whole entrance, without hiding the card or its controls.
    NSCAssert(peek.card.alphaValue == 1 && peek.controls.alphaValue == 1 && peek.loadingCanvas && peek.contentTimer,
        @"a slow page leaves a visible card and usable controls");
    page.ready = YES; page.url = [NSURL URLWithString:@"https://example.com/"];
    page.host.layer.backgroundColor = NSColor.systemRedColor.CGColor;
    DPReadyDrain(0.05);
    NSCAssert(peek.motionVersion == version && !peek.loadingCanvas && !peek.contentTimer,
        @"first paint only removes the fallback canvas, without replaying or delaying the entrance");
    [peek close:0]; DPReadyDrain(0.28);
    NSCAssert(page.closed && !peek.superview, @"the painted page closes normally");

    page = [DPReadyPeekPage new]; page.url = [NSURL URLWithString:@"https://example.com/"];
    peek = DPPeekShowCard(window, page, point);
    [peek close:0]; page.ready = YES; DPReadyDrain(0.32);
    NSCAssert(page.closed && !peek.superview && !peek.contentTimer && !peek.loadingCanvas && peek.controls.alphaValue == 0,
        @"closing before first paint cancels the wait and cannot resurrect the card or controls");
}
