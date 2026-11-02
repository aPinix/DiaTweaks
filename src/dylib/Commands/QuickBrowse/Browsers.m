#import "QuickBrowse.h"
#import <objc/message.h>

static NSHashTable *DPMiniBrowsers;
static NSMapTable *DPMiniDelegates, *DPMiniBrowserWindows;

NSArray *DPBrowseKnownBrowsers(void) { return DPMiniBrowsers.allObjects ?: @[]; }
id DPBrowseBrowserDelegate(id browser) { return [DPMiniDelegates objectForKey:browser]; }
void DPBrowseRememberBrowser(id browser, id delegate, NSWindow *window) {
    if (!DPIsKind(browser, DPDiaBrowser)) return;
    [DPMiniBrowsers addObject:browser];
    if (delegate) [DPMiniDelegates setObject:delegate forKey:browser];
    if ([window isKindOfClass:NSWindow.class]) [DPMiniBrowserWindows setObject:window forKey:browser];
}
NSWindow *DPBrowseWindowForBrowser(id browser) {
    NSWindow *remembered = [DPMiniBrowserWindows objectForKey:browser];
    if (remembered) return remembered;
    id (*get)(id,SEL) = (void *)objc_msgSend;
    NSString *identifier = [browser respondsToSelector:@selector(windowIdentifier)] ? get(browser,@selector(windowIdentifier)) : nil;
    if (![identifier isKindOfClass:NSString.class] || !identifier.length) return nil;
    for (NSWindow *window in NSApp.windows) {
        NSString *native = window.identifier ?: @"", *accessibility = window.accessibilityIdentifier ?: @"";
        if ([native isEqual:identifier] || [accessibility isEqual:identifier] || [accessibility hasSuffix:identifier]) return window;
    }
    return nil;
}
DPBrowseSource *DPBrowseFallbackSource(NSWindow *window) {
    NSArray *browsers = DPBrowseKnownBrowsers();
    NSUInteger mainWindows = 0;
    for (NSWindow *candidate in NSApp.windows) if ([candidate.accessibilityIdentifier hasPrefix:@"bigBrowserWindow"]) mainWindows++;
    for (id browser in browsers) {
        NSWindow *owner = DPBrowseWindowForBrowser(browser);
        if (owner != window && !(owner == nil && browsers.count == 1 && mainWindows == 1)) continue;
        id delegate = DPBrowseBrowserDelegate(browser);
        if (![delegate respondsToSelector:@selector(browser:didCreateNewWebContents:isActive:)]) continue;
        DPBrowseSource *source = [DPBrowseSource new]; source.browser = browser;
        source.browserDelegate = delegate; source.window = window;
        if (DPBrowseSourceUsable(source)) return source;
    }
    return nil;
}
static id DPMini_browser(id self, SEL _cmd, id context, id delegate, id identifier) {
    id browser = DPCallOriginal(DPMini_browser, self, context, delegate, identifier);
    DPBrowseRememberBrowser(browser, delegate, nil); return browser;
}
static void DPMini_delegate(id self, SEL _cmd, id delegate) {
    DPCallOriginal(DPMini_delegate, self, delegate); DPBrowseRememberBrowser(self, delegate, nil);
}
static void DPMini_window(id self, SEL _cmd, NSWindow *window) {
    DPCallOriginal(DPMini_window, self, window); DPBrowseRememberBrowser(self, nil, window);
}
void DPBrowseInstallBrowsers(void) {
    DPMiniBrowsers = [NSHashTable weakObjectsHashTable];
    DPMiniDelegates = [NSMapTable weakToWeakObjectsMapTable]; DPMiniBrowserWindows = [NSMapTable weakToWeakObjectsMapTable];
    DPHook(DPDiaBrowserApplication, @selector(createBrowser:withDelegate:forWindow:), (IMP)DPMini_browser);
    DPHook(DPDiaBrowser, @selector(setDelegate:), (IMP)DPMini_delegate);
    DPHook(DPDiaBrowser, @selector(setWindow:), (IMP)DPMini_window);
}
