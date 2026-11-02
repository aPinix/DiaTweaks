#import "Launcher.h"

@implementation DPMiniLauncher (Activation)
- (void)focus {
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:self.search];
    if (NSApp.active) return;
    self.presenting = YES;
    if (self.activationObserver) [NSNotificationCenter.defaultCenter removeObserver:self.activationObserver];
    __weak DPMiniLauncher *weak = self;
    self.activationObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSApplicationDidBecomeActiveNotification
        object:NSApp queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        DPMiniLauncher *launcher = weak;
        if (!launcher) return;
        [NSNotificationCenter.defaultCenter removeObserver:launcher.activationObserver];
        launcher.activationObserver = nil;
        // Dia restores its main window on activation. Present after that handler finishes.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 80 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            if (DPCurrentMiniLauncher != launcher || !launcher.window.visible) return;
            [launcher.window makeKeyAndOrderFront:nil];
            [launcher.window makeFirstResponder:launcher.search];
            launcher.presenting = NO;
        });
    }];
    NSRunningApplication *previous = NSWorkspace.sharedWorkspace.frontmostApplication;
    if (previous && previous.processIdentifier != NSRunningApplication.currentApplication.processIdentifier)
        [NSRunningApplication.currentApplication activateFromApplication:previous options:0];
}
@end
