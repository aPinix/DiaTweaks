#import "BrowserToolbar.h"

NSArray<DPBrowseSource *> *DPBrowseMiniSourcesForProfile(DPBrowseWindow *owner, NSArray<DPBrowseSource *> *sources) {
    NSMutableArray *result = [NSMutableArray array]; NSMutableSet *windows = [NSMutableSet set];
    for (DPBrowseSource *source in sources) {
        if (![source.window.accessibilityIdentifier hasPrefix:@"bigBrowserWindow"]
            || [windows containsObject:source.window] || ![owner canPromoteToSource:source]) continue;
        [windows addObject:source.window]; [result addObject:source];
    }
    return result;
}

@implementation DPBrowseWindow (OpenDestinations)
- (NSArray<DPBrowseSource *> *)destinationSources {
    NSMutableArray *sources = [NSMutableArray array]; if (self.source) [sources addObject:self.source];
    NSMutableArray *windows = [NSApp.orderedWindows mutableCopy];
    for (NSWindow *window in NSApp.windows) if (![windows containsObject:window]) [windows addObject:window];
    for (NSWindow *window in windows) {
        if (![window.accessibilityIdentifier hasPrefix:@"bigBrowserWindow"]) continue;
        DPBrowseSource *source = nil;
        for (id page in DPBrowseKnownContents()) {
            DPBrowseSource *candidate = DPBrowseSourceFor(page);
            if (candidate.window == window) { source = candidate; break; }
        }
        source = source ?: DPBrowseFallbackSource(window);
        if (source) [sources addObject:source];
    }
    return DPBrowseMiniSourcesForProfile(self, sources);
}
- (void)showOpenDestinations:(id)sender {
    if (self.closing || self.promoting || self.transferred) return;
    if (self.destinationPopover.shown) return [self.destinationPopover close];
    DPMiniBrowserDestinations *controller = [DPMiniBrowserDestinations new];
    controller.owner = self; controller.sources = [self destinationSources]; controller.filtered = controller.sources;
    NSPopover *popover = [NSPopover new]; popover.behavior = NSPopoverBehaviorTransient;
    popover.contentViewController = controller; self.destinationPopover = popover;
    NSView *anchor = [sender isKindOfClass:NSView.class] ? sender : self.openControl;
    [popover showRelativeToRect:anchor.bounds ofView:anchor preferredEdge:NSRectEdgeMinY];
    [popover.contentViewController.view.window makeFirstResponder:controller.search];
}
@end
