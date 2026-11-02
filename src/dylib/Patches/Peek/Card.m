#import "Patches/Peek/Peek.h"

// The card sits over the window's page area only, so the sidebar stays sharp and usable, as in Arc. It's a child of
// the window's own root view: replacing the root clears the controller Dia relies on.
@implementation DPPeekCard

- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

// Arc's card is nearly full height and inset at the sides, with the controls in the right margin.
- (NSRect)cardFrame { return NSInsetRect(self.bounds, NSWidth(self.bounds) * 0.09, MAX(10, NSHeight(self.bounds) * 0.012)); }

- (void)layout {
    [super layout];
    self.blur.frame = self.bounds;
    self.card.frame = self.cardFrame;
    self.clip.frame = self.card.bounds;
    self.host.frame = self.clip.bounds;
    NSSize size = self.controls.frame.size;
    self.controls.frame = (NSRect){{NSMaxX(self.card.frame) + 12, NSMinY(self.card.frame)}, size};
}

// Follows the page area as the sidebar opens and closes.
- (void)followPane {
    NSView *pane = self.pane, *root = self.superview;
    if (!pane.window || !root) return;
    NSRect frame = [root convertRect:pane.bounds fromView:pane];
    if (!NSEqualRects(frame, self.frame)) self.frame = frame;
}

- (void)mouseDown:(NSEvent *)event { [self close:0]; }
- (void)rightMouseDown:(NSEvent *)event {}
- (void)scrollWheel:(NSEvent *)event {}
- (void)control:(NSButton *)sender { [self close:sender.tag]; }

- (void)stopWatching {
    self.motionVersion++;
    if (self.monitor) [NSEvent removeMonitor:self.monitor];
    if (self.paneObserver) [NSNotificationCenter.defaultCenter removeObserver:self.paneObserver];
    self.monitor = self.paneObserver = nil;
    self.controls.alphaValue = 0;
    [self restoreBackdrop];
    DPPeekStopIndicator(self);
}

// Keep the same live page in the card until it reaches the destination. Escape can cancel an expansion mid-flight.
- (void)close:(NSInteger)exit {
    if (self.closing && !(self.expanding && exit == 0)) return;
    self.closing = YES;
    self.expanding = exit != 0;
    self.controls.alphaValue = 0;
    if (exit) [self animateExpand:exit completion:^{ [self finish:exit]; }];
    else [self animateOut:^{ [self finish:0]; }];
}

- (void)handOver {
    self.closing = YES;
    [self stopWatching];
    [self.page detachFromPaneHostView:self.host];
    [self removeFromSuperview];
}

@end

DPPeekCard *DPPeekCardIn(NSWindow *window) {
    for (NSView *view in window.contentView.subviews)
        if ([view isKindOfClass:DPPeekCard.class]) return (DPPeekCard *)view;
    return nil;
}
