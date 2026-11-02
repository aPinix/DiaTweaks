#import "Patches/Peek/Peek.h"

// Peek is immediately above the browser frame. Dia's transient sidebar remains above both.
@implementation DPPeekCard

- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

// Arc's card is nearly full height and inset at the sides, with the controls in the right margin.
- (NSRect)cardFrame {
    CGFloat inset = MIN(MAX(54, NSWidth(self.bounds) * 0.10), NSWidth(self.bounds) / 4);
    return NSInsetRect(self.bounds, inset, MAX(10, NSHeight(self.bounds) * 0.012));
}

- (void)layout {
    [super layout];
    self.card.frame = self.cardFrame;
    self.clip.frame = self.card.bounds;
    self.host.frame = self.clip.bounds;
    NSSize size = self.controls.frame.size;
    self.controls.frame = (NSRect){{MIN(NSMaxX(self.card.frame) + 6, NSWidth(self.bounds) - size.width - 5), NSMinY(self.card.frame) + 2}, size};
}

// Follows the page area as the sidebar opens and closes.
- (void)followPane {
    NSView *surface = self.surface, *root = surface.superview;
    if (!surface.window || !root) return;
    if (self.superview != root) { [self removeFromSuperview]; [root addSubview:self positioned:NSWindowAbove relativeTo:surface]; }
    NSRect frame = [root convertRect:surface.bounds fromView:surface];
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
    return (id)DPFindView(window.contentView, ^BOOL(NSView *view) { return [view isKindOfClass:DPPeekCard.class]; });
}
