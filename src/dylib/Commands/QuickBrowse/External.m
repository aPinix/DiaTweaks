#import "Launcher.h"

static NSMutableArray<NSURL *> *DPMiniPendingLinks;
static __weak id DPMiniPendingDelegate;
static NSTimer *DPMiniPendingTimer;
static void DPBrowse_external(id self, SEL _cmd, NSApplication *app, NSArray<NSURL *> *urls);

BOOL DPBrowseHasPendingLinks(void) { return DPMiniPendingLinks.count != 0; }
static void DPBrowseForward(id delegate, NSApplication *app, NSArray *urls) {
    if (!delegate || !urls.count) return;
    SEL selector = @selector(application:openURLs:);
    void (*original)(id,SEL,id,id) = (void *)DPOriginalIMP(delegate, selector, (IMP)DPBrowse_external);
    original(delegate, selector, app, urls);
}
static void DPBrowseDrainLinks(void) {
    static NSUInteger polls;
    if (DPMiniPendingTimer) return;
    polls = 0;
    DPMiniPendingTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer) {
        DPBrowseSource *source = DPBrowseFrontSource();
        BOOL fallback = !DPDiaMini.on || !DPDiaMiniExternal.on || ++polls >= 120;
        if (!fallback && !source) { DPBrowsePrepareSource(); return; }
        NSArray *links = DPMiniPendingLinks.copy; [DPMiniPendingLinks removeAllObjects];
        [timer invalidate]; DPMiniPendingTimer = nil;
        NSMutableArray *remaining = [NSMutableArray new];
        for (NSURL *url in links)
            if (fallback || !DPBrowseShow(url, source)) [remaining addObject:url];
            else DPBrowseRemember(source, url, url.host);
        DPBrowseForward(DPMiniPendingDelegate, NSApp, remaining);
        DPBrowseReleaseSource();
    }];
}
static void DPBrowse_external(id self, SEL _cmd, NSApplication *app, NSArray<NSURL *> *urls) {
    if (!DPDiaMini.on || !DPDiaMiniExternal.on) return DPCallOriginal(DPBrowse_external, self, app, urls);
    DPBrowseSource *source = DPBrowseFrontSource();
    NSMutableArray *remaining = [NSMutableArray new];
    for (NSURL *url in urls) {
        if (!DPBrowseURL(url)) { [remaining addObject:url]; continue; }
        if (source && DPBrowseShow(url, source)) { DPBrowseRemember(source, url, url.host); continue; }
        DPMiniPendingLinks = DPMiniPendingLinks ?: [NSMutableArray new];
        [DPMiniPendingLinks addObject:url]; DPMiniPendingDelegate = self;
    }
    if (DPMiniPendingLinks.count) DPBrowseDrainLinks();
    if (remaining.count) DPCallOriginal(DPBrowse_external, self, app, remaining);
}
static void DPBrowse_appDelegate(id self, SEL _cmd, id delegate) {
    DPCallOriginal(DPBrowse_appDelegate, self, delegate);
    DPHookClass(object_getClass(delegate), @selector(application:openURLs:), (IMP)DPBrowse_external);
}
void DPBrowseInstallExternal(void) {
    DPHookClass(NSApplication.class, @selector(setDelegate:), (IMP)DPBrowse_appDelegate);
    DPHookClass(object_getClass(NSApp.delegate), @selector(application:openURLs:), (IMP)DPBrowse_external);
}
