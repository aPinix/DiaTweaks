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
    DPReadyPeekPage *page = [DPReadyPeekPage new]; page.url = [NSURL URLWithString:@"https://example.com/"];
    NSPoint point = [window convertPointToScreen:NSMakePoint(325, 480)];
    DPPeekCard *peek = DPPeekShowCard(window, page, point);
    DPReadyDrain(0.30); // First paint can arrive after the entire 200 ms entrance would have finished.
    NSCAssert(peek.card.alphaValue == 0 && peek.openingTimer, @"the empty Chromium host does not consume the entrance");
    page.ready = YES;
    page.host.layer.backgroundColor = NSColor.systemRedColor.CGColor;
    DPReadyDrain(0.035);
    CAAnimationGroup *opening = (id)[peek.card.layer animationForKey:@"peek"];
    NSCAssert(opening && opening.duration >= 0.18 && peek.card.alphaValue == 1 && !peek.openingTimer,
        @"the first painted page gets its own full opening animation");
    CABasicAnimation *grow = (id)opening.animations.firstObject;
    NSCAssert([grow.keyPath isEqual:@"transform"]
        && CATransform3DEqualToTransform([grow.fromValue CATransform3DValue], [peek transformToFrame:peek.originFrame]),
        @"the delayed opening still grows from the original click");
    [peek close:0]; DPReadyDrain(0.28);
    NSCAssert(page.closed && !peek.superview, @"the painted page closes normally");

    page = [DPReadyPeekPage new]; page.url = [NSURL URLWithString:@"https://example.com/"];
    peek = DPPeekShowCard(window, page, point);
    [peek close:0]; page.ready = YES; DPReadyDrain(0.32);
    NSCAssert(page.closed && !peek.superview && !peek.openingTimer && peek.controls.alphaValue == 0,
        @"closing before first paint cancels the wait and cannot resurrect the card or controls");
}
