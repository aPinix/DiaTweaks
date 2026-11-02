#import "QuickBrowse.h"

DPBrowseSource *DPBrowseFrontSource(void) {
    for (DPBrowseWindow *preview in DPBrowseWindows)
        if (preview.window.isKeyWindow) return preview.source;
    NSMutableOrderedSet *windows = [NSMutableOrderedSet orderedSetWithArray:NSApp.orderedWindows];
    [windows addObjectsFromArray:NSApp.windows];
    for (NSWindow *window in windows) {
        if (![window.accessibilityIdentifier hasPrefix:@"bigBrowserWindow"]) continue;
        for (id<DPBrowseContents> contents in DPBrowseKnownContents())
            if (DPBrowseHost(contents).window == window || contents.nativeView.window == window) {
                DPBrowseSource *source = DPBrowseSourceFor(contents);
                if (DPBrowseSourceUsable(source)) return source;
            }
        for (id contents in DPBrowseKnownContents()) {
            DPBrowseSource *source = DPBrowseSourceFor(contents);
            if (source.window == window && DPBrowseSourceUsable(source)) return source;
        }
        DPBrowseSource *source = DPBrowseFallbackSource(window);
        if (source) return source;
    }
    return nil;
}
