#import "Patches/Peek/Peek.h"
#import "Patches/Peek/Indicator.h"

// Arc's Peek: Shift-click a link and it opens in a card over the page you're on, then becomes a tab or a split view
// pane only if you expand or split it. Dispositions are ArcCore's own ArcWebContentsNavigationDisposition, numbered
// differently from Chromium's: 4 there is picture-in-picture.
enum { DPIgnoreAction = 0, DPCurrentTab = 1, DPForegroundTab = 2, DPBackgroundTab = 3, DPNewWindow = 5, DPPopup = 6 };
static __weak NSWindow *DPPeekClickWindow;
static NSTimeInterval DPPeekClickTime;

void DPPeekRememberClick(NSWindow *window, NSEventModifierFlags flags) {
    NSEventModifierFlags mask = NSEventModifierFlagShift | NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagControl;
    DPPeekClickWindow = (flags & mask) == NSEventModifierFlagShift ? window : nil;
    DPPeekClickTime = NSProcessInfo.processInfo.systemUptime;
}

// ArcCore reports a Shift-click as a popup; new tabs and windows count too.
static BOOL DPPeekWanted(NSInteger disposition, id page) {
    BOOL elsewhere = disposition == DPForegroundTab || disposition == DPBackgroundTab || disposition == DPPopup || disposition == DPNewWindow;
    NSEventModifierFlags mask = NSEventModifierFlagShift | NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagControl;
    BOOL held = (NSEvent.modifierFlags & mask) == NSEventModifierFlagShift;
    NSWindow *window = DPPeekWindowForPage(page) ?: NSApp.keyWindow;
    BOOL recent = DPPeekClickWindow && DPPeekClickWindow == window
        && NSProcessInfo.processInfo.systemUptime - DPPeekClickTime < 2;
    return DPPeek.on && elsewhere && (held || recent);
}

// target="_blank" links and window.open arrive here with a page already made. Peek turns it down and makes its own.
static void DPWebContent_didCreate(id self, SEL _cmd, id webContents, id newWebContent, NSURL *url, NSInteger disposition) {
    if (!DPPeekCanLoad(url) || !DPPeekWanted(disposition, webContents) || !(DPPeekShows(webContents) || DPPeekCanOpen(webContents)))
        return (void)DPCallOriginal(DPWebContent_didCreate, self, webContents, newWebContent, url, disposition);
    DPCallOriginal(DPWebContent_didCreate, self, webContents, newWebContent, url, (NSInteger)DPIgnoreAction);
    // A link opened from inside a Peek loads in that Peek, as in Arc.
    if (DPPeekShows(webContents)) return DPPeekLoad(webContents, url);
    NSWindow *window = DPPeekWindowForPage(webContents) ?: NSApp.keyWindow;
    DPPeekClickWindow = nil;
    NSPoint origin = NSEvent.mouseLocation;
    dispatch_async(dispatch_get_main_queue(), ^{ DPPeekOpen(window, url, origin, self, webContents); });
}

// Plain links that Chromium wants anywhere but the current tab are asked about here first; Dia answers with the
// disposition to open them with.
static NSInteger DPWebContent_decidePolicy(id self, SEL _cmd, id webContents, id action) {
    NSURL *url = [action valueForKey:@"url"];
    if (!DPPeekCanLoad(url) || !DPPeekWanted([[action valueForKey:@"navigationDisposition"] integerValue], webContents))
        return DPCallOriginal(DPWebContent_decidePolicy, self, webContents, action);
    if (DPPeekShows(webContents)) return DPCurrentTab;
    if (!DPPeekCanOpen(webContents)) return DPCallOriginal(DPWebContent_decidePolicy, self, webContents, action);
    NSWindow *window = DPPeekWindowForPage(webContents) ?: NSApp.keyWindow;
    DPPeekClickWindow = nil;
    NSPoint origin = NSEvent.mouseLocation;
    dispatch_async(dispatch_get_main_queue(), ^{ DPPeekOpen(window, url, origin, self, webContents); });
    return DPIgnoreAction;
}

static void DPInstallPeek(void) {
    DPPeekInstallPages();
    DPOnLaunch(^{
        DPPeekInstallTabSpacing();
        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown handler:^NSEvent *(NSEvent *event) {
            DPPeekRememberClick(event.window, event.modifierFlags);
            return event;
        }];
        // Dia's Swift classes resolve only once its runtime is up.
        DPHook(DPDiaWebContent, @selector(webContents:didCreateNewWebContent:targetURL:disposition:), (IMP)DPWebContent_didCreate);
        DPHook(DPDiaWebContent, @selector(webContents:decidePolicyForNavigationAction:), (IMP)DPWebContent_decidePolicy);
    });
}

static void DPApplyPeek(DPPatch *patch) {
    if (!patch->on) for (NSWindow *window in NSApp.windows) [DPPeekCardIn(window) close:0];
}

DP_PATCH(DPPeek) {
    .key = @"peek",
    .order = 210,
    .title = @"Peek",
    .detail = @"Shift-click a link to preview it over the current page. The page behind scales back slightly; expanding moves the live preview into a tab. The source tab or pinned tile shows the preview’s favicon. Escape or ⌘W closes it; ⌘O expands it.",
    .symbol = @"eye.fill",
    .tint = @"systemMintColor",
    .section = @"Browsing",
    .classes = DPClasses(DPDiaBrowserContext, DPDiaWebContents, DPDiaWebContentsConfiguration,
        DPDiaContentPane, DPDiaTabView, DPDiaTabContentView, DPDiaFavoriteTab),
    .install = DPInstallPeek,
    .apply = DPApplyPeek,
    .verify = DPVerifyPeek,
};
