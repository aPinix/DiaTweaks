#import "Launcher.h"

@implementation DPMiniLauncher (Results)
- (void)resizeForResults {
    CGFloat rows = MIN(DPMiniResultLimit, self.suggestions.count);
    CGFloat height = DPMiniListTop + MAX(1, rows) * DPMiniRowHeight + DPMiniListBottom;
    NSScreen *screen = self.window.screen ?: NSScreen.mainScreen;
    height = MIN(height, MAX(130, NSHeight(screen.visibleFrame) - 32));
    NSRect frame = self.window.frame; frame.origin.y += frame.size.height - height; frame.size.height = height;
    frame.origin.y = MAX(NSMinY(screen.visibleFrame), MIN(frame.origin.y, NSMaxY(screen.visibleFrame) - height));
    [self.window setFrame:frame display:YES];
    CGFloat width = self.window.contentView.bounds.size.width;
    CGFloat listHeight = MAX(0, MIN(MAX(1, rows) * DPMiniRowHeight, height - DPMiniListTop - DPMiniListBottom));
    self.scroll.frame = NSMakeRect(10, DPMiniListTop, width - 20, listHeight);
    self.scroll.hidden = rows == 0; self.scroll.hasVerticalScroller = listHeight < rows * DPMiniRowHeight;
    self.table.tableColumns.firstObject.width = width - 20;
    self.table.frame = NSMakeRect(0, 0, width - 20, rows * DPMiniRowHeight);
    self.status.frame = NSMakeRect(24, DPMiniListTop + (listHeight - 18) / 2, width - 48, 18);
    [self updateLauncherShadow];
}
@end
