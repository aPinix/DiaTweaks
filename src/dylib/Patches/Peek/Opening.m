#import "Patches/Peek/Peek.h"
#import <objc/message.h>

@implementation DPPeekCard (Opening)
- (void)waitForContent {
    // ArcCore reports the first displayable page separately from attaching its initially empty host.
    if (![self.page respondsToSelector:@selector(isReadyToDisplay)]) { [self animateIn]; return; }
    BOOL reduce = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    [self animateBackdrop:YES duration:reduce ? 0.08 : DPPeekGrow];
    __weak DPPeekCard *weak = self;
    self.openingTimer = [NSTimer timerWithTimeInterval:1.0 / 60 repeats:YES block:^(NSTimer *timer) {
        DPPeekCard *peek = weak;
        if (!peek || peek.closing || !peek.window) { [timer invalidate]; peek.openingTimer = nil; return; }
        BOOL (*ready)(id, SEL) = (void *)objc_msgSend;
        NSURL *url = [(NSObject *)peek.page valueForKey:@"url"];
        if (!ready(peek.page, @selector(isReadyToDisplay)) || !DPPeekCanLoad(url)) return;
        [timer invalidate]; peek.openingTimer = nil;
        [peek animateIn];
    }];
    [NSRunLoop.mainRunLoop addTimer:self.openingTimer forMode:NSRunLoopCommonModes];
}
@end
