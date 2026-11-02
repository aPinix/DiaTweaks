#import "CommandBar.h"

@implementation DPCommandBarLauncher (Placement)
- (void)trackSourceWindow {
    NSWindow *source = self.source.window;
    NSWindow *panel = self.isWindowLoaded ? self.window : nil;
    if (source == self.observedSource && (!source.visible || panel.parentWindow == source)) return;
    for (id observer in @[self.sourceResizeObserver ?: NSNull.null, self.sourceCloseObserver ?: NSNull.null])
        if (observer != NSNull.null) [NSNotificationCenter.defaultCenter removeObserver:observer];
    self.observedSource = source; self.sourceResizeObserver = self.sourceCloseObserver = nil;
    if (!source) return;
    if (panel && source.visible && panel.parentWindow != source) [source addChildWindow:panel ordered:NSWindowAbove];
    __weak DPCommandBarLauncher *weak = self;
    self.sourceResizeObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowDidResizeNotification object:source queue:nil
        usingBlock:^(NSNotification *note) { [weak resizeForResults]; }];
    self.sourceCloseObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification object:source queue:nil
        usingBlock:^(NSNotification *note) { [weak close]; }];
}
- (NSRect)launcherFrameForHeight:(CGFloat)height {
    [self trackSourceWindow];
    NSWindow *source = self.source.window;
    NSScreen *screen = source.screen ?: NSScreen.mainScreen;
    NSRect visible = screen.visibleFrame, content = visible;
    if (source.contentView) content = [source convertRectToScreen:[source.contentView convertRect:source.contentView.bounds toView:nil]];
    NSRect available = NSIntersectionRect(visible, content);
    if (NSIsEmptyRect(available)) available = visible;
    CGFloat width = MIN(764, MAX(1, NSWidth(available) - 32));
    height = MIN(height, MAX(1, NSHeight(available) - 32));
    CGFloat x = NSMidX(content) - width / 2;
    CGFloat y = NSMaxY(content) - NSHeight(content) / 3 - height;
    return NSMakeRect(MAX(NSMinX(available) + 16, MIN(x, NSMaxX(available) - width - 16)),
        MAX(NSMinY(available) + 16, MIN(y, NSMaxY(available) - height - 16)), width, height);
}
@end
