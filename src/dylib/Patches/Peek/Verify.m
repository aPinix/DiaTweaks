#import "Patches/Peek/Peek.h"

NSString *DPVerifyPeek(DPPatch *patch) {
    for (DPPeekCard *peek in DPFindViews("DPPeekCard")) {
        if (!patch->on) return @"a disabled Peek is still open";
        if (!peek.page || peek.host.window != peek.window) return @"the preview page is detached";
        NSView *root = peek.window.contentView;
        NSView *badge = DPFindView(root, ^BOOL(NSView *view) { return DPHasLabel(view, @"Peek open"); });
        if (!badge) return @"the source favicon is missing";
        for (NSView *row in DPFindViews(DPDiaTabView)) {
            if (row.window != peek.window || !NSContainsRect([root convertRect:row.bounds fromView:row], badge.frame)) continue;
            NSView *close = DPFindView(row, ^BOOL(NSView *view) { return [view.accessibilityIdentifier isEqual:@"tabCloseButton"]; });
            if (close && !close.hiddenOrHasHiddenAncestor && NSIntersectsRect([root convertRect:close.bounds fromView:close], badge.frame))
                return @"the source favicon overlaps the close button";
        }
    }
    return nil;
}
