#import "BrowserToolbar.h"
#import "BrowserDestinations.h"

// A fresh native tab menu must belong to the exact adopted page before its move callback runs.
BOOL DPBrowseAdoptedPageSelected(id<DPBrowseContents> page, NSWindow *window) {
    NSView *view = page.nativeView;
    if (!window.visible || NSApp.keyWindow != window || view.window != window
        || view.hiddenOrHasHiddenAncestor || NSIsEmptyRect(view.visibleRect) || !page.hasFocus) return NO;
    if (!NSIntersectsRect([view convertRect:view.bounds toView:window.contentView],window.contentView.bounds)) return NO;
    NSResponder *responder = window.firstResponder;
    return responder == view || ([responder isKindOfClass:NSView.class] && [(NSView *)responder isDescendantOf:view]);
}

@implementation DPBrowseWindow (NativeDestinationTransfer)
- (void)openNativeDestination:(DPMiniNativeDestination *)choice {
    if (!choice || (!choice.enabled && choice.state != NSControlStateValueOn) || self.promoting || self.closing) return;
    [self.destinationPopover close];
    id<DPBrowseContents> page = self.contents;
    NSWindow *window = self.source.window;
    BOOL current = choice.state == NSControlStateValueOn;
    [self promoteToSource:self.source completion:^(BOOL adopted) {
        if (!adopted || current) return;
        // Adoption can finish before native focus/tab selection settles. Never reuse the source tab's callback.
        __block NSUInteger attempts = 0;
        [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *timer) {
            BOOL (^selected)(void) = ^{ return DPBrowseAdoptedPageSelected(page, window); };
            if (!selected() && window.visible && ++attempts < 12) return;
            [timer invalidate];
            if (!selected()) return;
            NSMenu *menu = DPBrowseMenuForSelectedNativeTab(window, selected);
            if (!DPBrowseInvokeNativeDestination(menu, choice, selected) && selected()) {
                NSAlert *alert = [NSAlert new]; alert.messageText = @"The page is open in Dia";
                alert.informativeText = @"Dia could not move this tab to the selected destination. Use the tab’s Move menu to choose a destination.";
                [alert beginSheetModalForWindow:window completionHandler:nil];
            }
            // Successful dispatch belongs to Dia; its native move flow can still present a dialog.
        }];
    }];
}
@end
