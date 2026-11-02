#import "QuickBrowse.h"
#import "Launcher.h"
#import "../Shortcuts/Shortcut.h"

NSMutableSet<DPBrowseWindow *> *DPBrowseWindows;
NSMenuItem *DPNewMiniItem;

BOOL DPBrowseCompatible(void) {
    const struct { const char *cls; SEL sel; } methods[] = {
        {DPDiaBrowser, @selector(createWebContents:)}, {DPDiaWebContents, @selector(createPaneHostView)},
        {DPDiaWebContents, @selector(attachToPaneHostView:)}, {DPDiaWebContents, @selector(detachFromPaneHostView:)},
        {DPDiaWebContents, @selector(nativeView)}, {DPDiaWebContents, @selector(navigationController)},
        {DPDiaWebContents, @selector(setUIDelegate:)}, {DPDiaWebContents, @selector(close)},
        {DPDiaWebContents, @selector(setNavigationDelegate:)},
        {DPDiaWebContentsConfiguration, @selector(setUntracked:)}, {DPDiaWebContentsConfiguration, @selector(setForeground:)},
        {DPDiaTablessDelegate, @selector(init)},
    };
    for (NSUInteger i = 0; i < sizeof methods / sizeof *methods; i++)
        if (!class_getInstanceMethod(objc_getClass(methods[i].cls), methods[i].sel)) return NO;
    return YES;
}

BOOL DPBrowseShow(NSURL *url, DPBrowseSource *source) {
    return DPBrowseOpen(url, source, NSZeroRect) != nil;
}

DPBrowseWindow *DPBrowseOpen(NSURL *url, DPBrowseSource *source, NSRect launcherFrame) {
    if (!DPDiaMini.on || !DPBrowseCompatible() || !DPBrowseSourceUsable(source)) return nil;
    if (url && !DPBrowseURL(url)) return nil;
    DPBrowseWindow *preview = [DPBrowseWindow new];
    preview.launcherFrame = launcherFrame;
    if (![preview startWithURL:url source:source]) return nil;
    [DPBrowseWindows addObject:preview];
    return preview;
}

void DPBrowseApply(DPPatch *patch) {
    DPNewMiniItem.hidden = !DPDiaMini.on;
    DPBrowseUpdateHotkey();
    if (!DPDiaMini.on) DPBrowseCloseLauncher();
    for (DPBrowseWindow *preview in DPBrowseWindows.copy)
        if (!DPDiaMini.on) [preview close];
}

NSString *DPBrowseVerify(DPPatch *patch) {
    if (patch->on && !DPBrowseCompatible()) return @"Dia’s native preview APIs are unavailable";
    if (patch == &DPDiaMini && DPNewMiniItem.hidden == patch->on) return @"the Dia Mini menu does not match its switch";
    if (!patch->on && DPBrowseHotkeyRegistered()) return @"a disabled Mini still owns its shortcut";
    for (NSView *page in DPFindViews("DPPageView")) {
        BOOL mini = DPFindView(page, ^BOOL(NSView *v) { return [v isKindOfClass:NSSwitch.class] && DPHasLabel(v, @"Dia Mini"); }) != nil;
        if (mini && !DPFindView(page, ^BOOL(NSView *v) { return [v isKindOfClass:DPMiniShortcutRecorder.class]; })) return @"the shortcut control is missing";
    }
    for (DPBrowseWindow *preview in DPBrowseWindows) {
        if (!patch->on) return @"a disabled preview is still open";
        if (!preview.host.window || preview.host.window != preview.window) return @"the native page is detached";
    }
    return nil;
}

void DPInstallQuickBrowse(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        DPBrowseWindows = [NSMutableSet new];
        if (!DPBrowseCompatible()) {
            DPDiaMini.unavailable = YES;
            DPDiaMini.on = NO;
            return (void)NSLog(@"DiaPatches: native previews unavailable on this Dia version");
        }
        DPBrowseInstallBrowsers(); DPBrowseInstallTracking(); DPBrowseInstallShortcutSettings();
        DPBrowseInstallCallbacks();
        DPBrowseInstallExternal();
        DPOnLaunch(^{
            DPNewMiniItem = DPAddMenuItem(@"File", @"New Dia Mini", ^{
                DPBrowseShowLauncher();
            });
            DPNewMiniItem.hidden = !DPDiaMini.on;
            DPBrowseInstallEvents();
            DPBrowseInstallExternal();
            DPBrowseUpdateHotkey();
        });
        DPOnQuit(^{ DPBrowseStopHotkey(); [DPCurrentMiniLauncher close]; for (DPBrowseWindow *preview in DPBrowseWindows.copy) [preview close]; });
    });
}
