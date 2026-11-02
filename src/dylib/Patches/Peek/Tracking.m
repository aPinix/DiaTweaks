#import "Patches/Peek/Peek.h"

static NSMapTable *DPPeekFactories;  // Each page -> the browser context or browser that made it.
static NSMapTable *DPPeekHosts;

NSWindow *DPPeekWindowForPage(id page) { return ((NSView *)[DPPeekHosts objectForKey:page]).window; }

static id DPContext_create(id self, SEL _cmd, id configuration) {
    id page = DPCallOriginal(DPContext_create, self, configuration);
    if (page) [DPPeekFactories setObject:self forKey:page];
    return page;
}

static id DPBrowser_create(id self, SEL _cmd, id configuration) {
    id page = DPCallOriginal(DPBrowser_create, self, configuration);
    if (page) [DPPeekFactories setObject:self forKey:page];
    return page;
}

static void DPPeek_restored(id self, SEL _cmd, id browser, id page, id session) {
    if (browser && page) [DPPeekFactories setObject:browser forKey:page];
    DPCallOriginal(DPPeek_restored, self, browser, page, session);
}
static void DPPeek_created(id self, SEL _cmd, id browser, id page, BOOL active) {
    if (browser && page) [DPPeekFactories setObject:browser forKey:page];
    DPCallOriginal(DPPeek_created, self, browser, page, active);
}

// Dia attaching a Peek's page somewhere else, such as when it's selected, means the card has to let go of it, or
// Dia's own pane stays white.
static void DPPage_attach(id self, SEL _cmd, NSView *host) {
    for (NSWindow *window in NSApp.windows) {
        DPPeekCard *peek = DPPeekCardIn(window);
        if (peek.page == self && host != peek.host) [peek handOver];
    }
    if (host) [DPPeekHosts setObject:host forKey:self];
    DPCallOriginal(DPPage_attach, self, host);
}

id DPPeekFactory(id source) { return source ? [DPPeekFactories objectForKey:source] : nil; }
BOOL DPPeekCanOpen(id source) { return DPPeekFactory(source) != nil; }

void DPPeekInstallPages(void) {
    DPPeekFactories = [NSMapTable weakToWeakObjectsMapTable];
    DPPeekHosts = [NSMapTable weakToWeakObjectsMapTable];
    DPHook(DPDiaBrowserContext, @selector(createWebContents:), (IMP)DPContext_create);
    DPHook(DPDiaBrowser, @selector(createWebContents:), (IMP)DPBrowser_create);
    DPHook(DPDiaBrowserDelegate, @selector(browser:didRestoreWebContents:withSessionId:), (IMP)DPPeek_restored);
    DPHook(DPDiaBrowserDelegate, @selector(browser:didCreateNewWebContents:isActive:), (IMP)DPPeek_created);
    DPHook(DPDiaWebContents, @selector(attachToPaneHostView:), (IMP)DPPage_attach);
    // A Peek can't outlast the window it's in.
    [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [DPPeekCardIn(note.object) close:0];
    }];
}
