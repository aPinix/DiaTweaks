#import "QuickBrowse.h"
#import "Launcher.h"
#import <objc/message.h>

@implementation DPBrowseSource
@end

static NSMapTable *DPBrowseBrowsers, *DPBrowseDelegates, *DPBrowseHosts;
static NSHashTable *DPBrowseClosedWindows;
NSArray *DPBrowseKnownContents(void) { return DPBrowseBrowsers.keyEnumerator.allObjects; }

BOOL DPBrowseSourceUsable(DPBrowseSource *source) {
    if (!source.browser || !source.window || [DPBrowseClosedWindows containsObject:source.window]) return NO;
    BOOL (*ready)(id,SEL) = (void *)objc_msgSend;
    BOOL initialized = ![source.browser respondsToSelector:@selector(isInitialized)] || ready(source.browser,@selector(isInitialized));
    return initialized && ((source.contents && source.delegate)
        || [source.browserDelegate respondsToSelector:@selector(browser:didCreateNewWebContents:isActive:)]);
}

NSView *DPBrowseHost(id contents) { return [DPBrowseHosts objectForKey:contents]; }
id DPBrowseDelegate(id contents) { return [DPBrowseDelegates objectForKey:contents]; }

id DPBrowseAutocompleteOwner(DPBrowseSource *source) {
    SEL selector = @selector(autocomplete:cursorPosition:preventInlineAutocomplete:startFresh:keyword:error:completion:);
    if ([source.browser respondsToSelector:selector]) return source.browser;
    id context = DPBrowseContext(source);
    id (*get)(id, SEL) = (void *)objc_msgSend;
    for (id browser in DPBrowseKnownBrowsers())
        if ([browser respondsToSelector:selector] && [browser respondsToSelector:@selector(context)]
            && [get(browser, @selector(context)) isEqual:context]) return browser;
    return nil;
}

static void DPBrowse_attach(id self, SEL _cmd, NSView *host) {
    if (host) [DPBrowseHosts setObject:host forKey:self];
    DPCallOriginal(DPBrowse_attach, self, host);
}
static void DPBrowse_detach(id self, SEL _cmd, NSView *host) {
    if (DPBrowseHost(self) == host) [DPBrowseHosts removeObjectForKey:self];
    DPCallOriginal(DPBrowse_detach, self, host);
}

static id DPBrowse_create(id self, SEL _cmd, id config) {
    id contents = DPCallOriginal(DPBrowse_create, self, config);
    DPBrowseRememberBrowser(self, nil, nil);
    if (contents) [DPBrowseBrowsers setObject:self forKey:contents];
    return contents;
}
static void DPBrowse_own(id self, SEL _cmd, id contents) {
    DPCallOriginal(DPBrowse_own, self, contents);
    if (contents) [DPBrowseBrowsers setObject:self forKey:contents];
}
static void DPBrowse_delegate(id self, SEL _cmd, id delegate) {
    DPBrowseRememberDelegate(self, delegate);
    DPCallOriginal(DPBrowse_delegate, self, delegate);
}
static void DPBrowse_restored(id self, SEL _cmd, id browser, id contents, id session) {
    DPBrowseRememberBrowser(browser, self, nil);
    if (browser && contents) [DPBrowseBrowsers setObject:browser forKey:contents];
    DPCallOriginal(DPBrowse_restored, self, browser, contents, session);
}
static void DPBrowse_created(id self, SEL _cmd, id browser, id contents, BOOL active) {
    DPBrowseRememberBrowser(browser, self, nil);
    if (browser && contents) [DPBrowseBrowsers setObject:browser forKey:contents];
    DPCallOriginal(DPBrowse_created, self, browser, contents, active);
}

void DPBrowseRememberDelegate(id contents, id delegate) {
    if (delegate) {
        [DPBrowseDelegates setObject:delegate forKey:contents];
        DPBrowseInstallDelegateHooks(object_getClass(delegate));
    } else [DPBrowseDelegates removeObjectForKey:contents];
}

DPBrowseSource *DPBrowseSourceFor(id contents) {
    for (DPBrowseWindow *preview in DPBrowseWindows)
        if (preview.contents == contents) return preview.source;
    id browser = [DPBrowseBrowsers objectForKey:contents], delegate = [DPBrowseDelegates objectForKey:contents];
    // Preloaded and tabless pages are temporary: their delegate cannot adopt a regular tab.
    if (!browser || !DPIsKind(delegate, DPDiaWebContent)
        || ![delegate respondsToSelector:@selector(webContents:didCreateNewWebContent:targetURL:disposition:)]) return nil;
    DPBrowseSource *source = [DPBrowseSource new];
    source.browser = browser; source.contents = contents; source.delegate = delegate;
    source.browserDelegate = DPBrowseBrowserDelegate(browser);
    source.window = DPBrowseHost(contents).window ?: ((id<DPBrowseContents>)contents).nativeView.window
        ?: DPBrowseWindowForBrowser(browser);
    return [DPBrowseClosedWindows containsObject:source.window] ? nil : source;
}


void DPBrowseInstallTracking(void) {
    DPBrowseBrowsers = [NSMapTable weakToWeakObjectsMapTable];
    DPBrowseDelegates = [NSMapTable weakToWeakObjectsMapTable];
    DPBrowseHosts = [NSMapTable weakToWeakObjectsMapTable];
    DPBrowseClosedWindows = [NSHashTable weakObjectsHashTable];
    [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [DPBrowseClosedWindows addObject:note.object];
    }];
    DPHook(DPDiaBrowser, @selector(createWebContents:), (IMP)DPBrowse_create);
    DPHook(DPDiaBrowserContext, @selector(createWebContents:), (IMP)DPBrowse_create);
    DPHook(DPDiaBrowser, @selector(takeOwnershipOfWebContents:), (IMP)DPBrowse_own);
    DPHook(DPDiaWebContents, @selector(attachToPaneHostView:), (IMP)DPBrowse_attach);
    DPHook(DPDiaWebContents, @selector(detachFromPaneHostView:), (IMP)DPBrowse_detach);
    DPHook(DPDiaWebContents, @selector(setUIDelegate:), (IMP)DPBrowse_delegate);
    DPHook(DPDiaBrowserDelegate, @selector(browser:didRestoreWebContents:withSessionId:), (IMP)DPBrowse_restored);
    DPHook(DPDiaBrowserDelegate, @selector(browser:didCreateNewWebContents:isActive:), (IMP)DPBrowse_created);
}
