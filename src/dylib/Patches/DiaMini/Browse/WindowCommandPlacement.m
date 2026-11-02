#import "WindowCommand.h"
#import "../Search/Provider.h"

@implementation DPMiniWindowCommand (Placement)
- (void)watchMiniOwner {
    [self stopWatchingMini];
    NSWindow *owner = self.miniOwner.window;
    if (!owner) return;
    __weak DPMiniWindowCommand *weak = self;
    self.miniResizeObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowDidResizeNotification object:owner queue:nil
        usingBlock:^(NSNotification *note) { [weak resizeForResults]; }];
    self.miniCloseObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification object:owner queue:nil
        usingBlock:^(NSNotification *note) { weak.restorePrevious = NO; [weak close]; }];
}
- (void)stopWatchingMini {
    for (id observer in @[self.miniResizeObserver ?: NSNull.null, self.miniCloseObserver ?: NSNull.null])
        if (observer != NSNull.null) [NSNotificationCenter.defaultCenter removeObserver:observer];
    self.miniResizeObserver = self.miniCloseObserver = nil;
}
- (NSRect)launcherFrameForHeight:(CGFloat)height {
    NSWindow *window = self.miniOwner.window;
    if (!window) return [super launcherFrameForHeight:height];
    [window.contentView layoutSubtreeIfNeeded];
    NSRect content = [window convertRectToScreen:[window.contentView convertRect:window.contentView.bounds toView:nil]];
    NSRect body = self.miniOwner.host.window ? [window convertRectToScreen:[self.miniOwner.host convertRect:self.miniOwner.host.bounds toView:nil]] : content;
    NSRect available = NSIntersectionRect(body, (window.screen ?: NSScreen.mainScreen).visibleFrame);
    if (NSIsEmptyRect(available)) available = content;
    CGFloat width = MIN(500, MAX(1, NSWidth(available) - 24));
    height = MIN(height, MAX(1, NSHeight(available) - 24));
    CGFloat x = NSMidX(content) - width / 2, y = NSMaxY(content) - NSHeight(content) / 3 - height;
    return NSMakeRect(MAX(NSMinX(available) + 12, MIN(x, NSMaxX(available) - width - 12)),
        MAX(NSMinY(available) + 12, MIN(y, NSMaxY(available) - height - 12)), width, height);
}
- (void)resizeForResults { [super resizeForResults]; if (self.search) [self refreshSiteSearchHeader]; }
@end
