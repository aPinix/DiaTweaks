#import "Patches/Peek/Indicator.h"

static char DPIndicatorKey;

// Decorations do not take the tab's click or drag target away.
@interface DPPeekBadge : NSImageView
@end
@implementation DPPeekBadge
- (NSView *)hitTest:(NSPoint)point { return nil; }
@end
@interface DPPeekOutline : NSView
@end
@implementation DPPeekOutline
- (NSView *)hitTest:(NSPoint)point { return nil; }
@end

@implementation DPPeekIndicator
- (void)update {
    DPPeekCard *peek = self.peek;
    NSView *root = peek.window.contentView;
    if (!peek.source && !peek.closing) { [peek close:0]; return; }
    if (!root) { self.badge.hidden = self.outline.hidden = YES; return; }
    if (!self.element || (self.row && self.row.window != peek.window)) {
        NSString *sourceTitle = [(NSObject *)peek.source valueForKey:@"title"];
        if ([sourceTitle isEqual:peek.window.title]) {
            id<NSAccessibility> moved = DPPeekSelectedTab(root);
            if ([(id)moved isKindOfClass:NSView.class]) { self.element = moved; self.row = (id)moved; }
        }
    }
    if (!self.element) { self.badge.hidden = self.outline.hidden = YES; return; }
    NSRect row = self.row.window == peek.window ? [root convertRect:self.row.bounds fromView:self.row]
        : [root convertRect:[peek.window convertRectFromScreen:self.element.accessibilityFrame] fromView:nil];
    BOOL hidden = NSIsEmptyRect(row) || !NSIntersectsRect(root.bounds, row) || self.row.hiddenOrHasHiddenAncestor;
    BOOL tile = DPIsKind(self.row, DPDiaFavoriteTab);
    NSView *reserved = tile ? nil : self.row;
    if (self.reservedRow != reserved) {
        DPPeekRestoreTabSpace(self.reservedRow);
        self.reservedRow = reserved;
    }
    DPPeekReserveTabSpace(reserved);
    self.badge.hidden = hidden; self.outline.hidden = hidden || !tile;
    self.badge.frame = DPPeekIndicatorFrame(row, tile, root.flipped);
    self.outline.frame = NSInsetRect(row, 1, 1);
    id icon = [(NSObject *)peek.page valueForKey:@"favicon"];
    self.badge.image = [icon isKindOfClass:NSImage.class] ? icon : [NSImage imageWithSystemSymbolName:@"globe" accessibilityDescription:nil];
    // Move above newly laid out sidebar children without participating in their layout.
    if (self.badge.superview != root) { [root addSubview:self.outline]; [root addSubview:self.badge]; }
}
@end

void DPPeekStartIndicator(DPPeekCard *peek) {
    DPPeekStopIndicator(peek);
    id<NSAccessibility> element = DPPeekSelectedTab(peek.window.contentView);
    DPPeekIndicator *state = [DPPeekIndicator new]; state.peek = peek; state.element = element;
    if ([(id)element isKindOfClass:NSView.class]) state.row = (id)element;
    NSView *root = peek.window.contentView;
    NSRect frame = [root convertRect:[peek.window convertRectFromScreen:element.accessibilityFrame] fromView:nil];
    NSView *hit = [root hitTest:[root.superview convertPoint:NSMakePoint(NSMidX(frame), NSMidY(frame)) fromView:root]];
    for (NSView *view = state.row ? nil : hit; view && view != root; view = view.superview) {
        NSRect bounds = [root convertRect:view.bounds fromView:view];
        if (fabs(NSWidth(bounds) - NSWidth(frame)) < 4 && fabs(NSHeight(bounds) - NSHeight(frame)) < 4) { state.row = view; break; }
    }
    state.badge = [DPPeekBadge new]; state.badge.wantsLayer = YES;
    state.badge.imageScaling = NSImageScaleProportionallyDown;
    state.badge.accessibilityLabel = @"Peek open";
    state.badge.layer.backgroundColor = NSColor.controlBackgroundColor.CGColor;
    state.badge.layer.cornerRadius = 4;
    state.badge.layer.shadowOpacity = 0.18; state.badge.layer.shadowRadius = 2;
    state.outline = [DPPeekOutline new]; state.outline.wantsLayer = YES;
    state.outline.layer.cornerRadius = 11; state.outline.layer.borderWidth = 1.5;
    state.outline.layer.borderColor = NSColor.controlAccentColor.CGColor;
    [root addSubview:state.outline]; [root addSubview:state.badge];
    DPSet(peek, &DPIndicatorKey, state); [state update];
    __weak DPPeekIndicator *weak = state;
    state.timer = [NSTimer scheduledTimerWithTimeInterval:0.15 repeats:YES block:^(NSTimer *_) { [weak update]; }];
}

void DPPeekStopIndicator(DPPeekCard *peek) {
    DPPeekIndicator *state = DPGet(peek, &DPIndicatorKey);
    DPPeekRestoreTabSpace(state.reservedRow);
    [state.timer invalidate]; [state.badge removeFromSuperview]; [state.outline removeFromSuperview];
    DPSet(peek, &DPIndicatorKey, nil);
}
