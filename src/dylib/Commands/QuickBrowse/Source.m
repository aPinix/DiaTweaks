#import "Launcher.h"

static NSWindow *DPMiniCreatedSource;
static id DPMiniSourceObserver;

void DPBrowsePrepareSource(void) {
    if (DPBrowseFrontSource() || DPMiniSourceObserver) return;
    for (NSWindow *window in NSApp.windows)
        if ([window.accessibilityIdentifier hasPrefix:@"bigBrowserWindow"]) return;
    NSMenu *file = [NSApp.mainMenu itemWithTitle:@"File"].submenu;
    NSMenuItem *newWindow = [file itemWithTitle:@"New Window"];
    if (!newWindow.action) return;
    DPMiniSourceObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil
        usingBlock:^(NSNotification *note) {
            NSWindow *window = note.object;
            if (![window.accessibilityIdentifier hasPrefix:@"bigBrowserWindow"]) return;
            DPMiniCreatedSource = window; [window orderOut:nil];
            [NSNotificationCenter.defaultCenter removeObserver:DPMiniSourceObserver]; DPMiniSourceObserver = nil;
            DPBrowseReleaseSource();
        }];
    [NSApp sendAction:newWindow.action to:newWindow.target from:newWindow];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (DPMiniSourceObserver) [NSNotificationCenter.defaultCenter removeObserver:DPMiniSourceObserver];
        DPMiniSourceObserver = nil;
    });
}

void DPBrowseReleaseSource(void) {
    if (DPBrowseWindows.count || DPCurrentMiniLauncher || DPBrowseHasPendingLinks() || !DPMiniCreatedSource) return;
    NSWindow *window = DPMiniCreatedSource; DPMiniCreatedSource = nil;
    if (!window.visible) [window performClose:nil];
}
