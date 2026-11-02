#import "Patches/Peek/Indicator.h"

static char DPPeekTabSpaceKey;

@interface DPPeekTabSpace : NSObject
@property (weak) NSView *row, *content;
@property NSRect nativeFrame, adjustedFrame;
@property BOOL applying, adjusted;
- (void)apply;
- (void)restore;
@end

@implementation DPPeekTabSpace
- (void)apply {
    if (self.applying) return;
    NSView *content = DPFindView(self.row, ^BOOL(NSView *view) { return DPIsKind(view, DPDiaTabContentView); });
    if (!content) return;
    if (content != self.content) { [self restore]; self.content = content; self.adjusted = NO; }
    NSRect frame = content.frame;
    if (!self.adjusted || !NSEqualRects(frame, self.adjustedFrame)) self.nativeFrame = frame;
    // Leave Dia's own close button, title truncation and hover handling inside the narrower content view.
    frame = self.nativeFrame;
    frame.size.width = MAX(0, NSWidth(frame) - 24);
    self.adjustedFrame = frame; self.adjusted = YES;
    if (NSEqualRects(frame, content.frame)) return;
    self.applying = YES;
    content.frame = frame;
    content.needsLayout = YES; [content layoutSubtreeIfNeeded];
    self.applying = NO;
}
- (void)restore {
    if (self.adjusted && NSEqualRects(self.content.frame, self.adjustedFrame)) {
        self.content.frame = self.nativeFrame;
        self.content.needsLayout = YES; [self.content layoutSubtreeIfNeeded];
    }
    self.adjusted = NO;
}
@end

static void DPPeekTab_layout(NSView *self, SEL _cmd) {
    DPCallOriginal(DPPeekTab_layout, self);
    [(DPPeekTabSpace *)DPGet(self, &DPPeekTabSpaceKey) apply];
}

void DPPeekInstallTabSpacing(void) {
    DPHook(DPDiaTabView, @selector(layout), (IMP)DPPeekTab_layout);
}
void DPPeekReserveTabSpace(NSView *row) {
    if (!DPIsKind(row, DPDiaTabView)) return;
    DPPeekTabSpace *space = DPGet(row, &DPPeekTabSpaceKey);
    if (!space) { space = [DPPeekTabSpace new]; space.row = row; DPSet(row, &DPPeekTabSpaceKey, space); }
    [space apply];
}
void DPPeekRestoreTabSpace(NSView *row) {
    if (!row) return;
    DPPeekTabSpace *space = DPGet(row, &DPPeekTabSpaceKey);
    DPSet(row, &DPPeekTabSpaceKey, nil);
    [space restore];
}
