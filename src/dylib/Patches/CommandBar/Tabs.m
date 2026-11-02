#import "CommandBar.h"
#import <objc/message.h>

static NSUInteger DPCommandAdoptionDepth;
BOOL DPCommandBarIsAdopting(void) { return DPCommandAdoptionDepth != 0; }

static BOOL DPCommandPageOwned(id<DPBrowseContents> page, DPBrowseSource *source) {
    NSWindow *destination = DPBrowseHost(page).window ?: page.nativeView.window;
    return (destination && destination == source.window) || DPIsKind(DPBrowseDelegate(page), DPDiaWebContent);
}

void DPCommandBarOpenTab(DPCommandBarLauncher *launcher, NSURL *url, void (^completion)(BOOL)) {
    DPBrowseSource *source = launcher.source;
    if (!DPBrowseURL(url) || !DPBrowseSourceUsable(source) || !launcher.launcherEnabled || !launcher.window.visible) return completion(NO);
    id browserDelegate = source.browserDelegate, delegate = source.delegate, original = source.contents;
    SEL browserAdopt = @selector(browser:didCreateNewWebContents:isActive:);
    SEL sourceAdopt = @selector(webContents:didCreateNewWebContent:targetURL:disposition:);
    BOOL useBrowser = [browserDelegate respondsToSelector:browserAdopt];
    if (!useBrowser && (!original || ![delegate respondsToSelector:sourceAdopt])) return completion(NO);
    Class configuration = objc_getClass(DPDiaWebContentsConfiguration);
    if (!configuration || ![source.browser respondsToSelector:@selector(createWebContents:)]) return completion(NO);
    id config = [configuration new];
    void (*flag)(id, SEL, BOOL) = (void *)objc_msgSend;
    flag(config, @selector(setForeground:), YES); flag(config, @selector(setUntracked:), NO);
    id (*create)(id, SEL, id) = (void *)objc_msgSend;
    id<DPBrowseContents> page = create(source.browser, @selector(createWebContents:), config);
    SEL load = @selector(load:initiatorOrigin:);
    if (!page || ![page.navigationController respondsToSelector:load]) { [page close]; return completion(NO); }
    @try {
        ((id (*)(id, SEL, id, id))objc_msgSend)(page.navigationController, load, url, nil);
        DPCommandAdoptionDepth++;
        @try {
            if (useBrowser) ((void (*)(id, SEL, id, id, BOOL))objc_msgSend)(browserDelegate, browserAdopt, source.browser, page, YES);
            else ((void (*)(id, SEL, id, id, id, NSInteger))objc_msgSend)(delegate, sourceAdopt, original, page, url, DPBrowseForegroundTab);
        } @finally { DPCommandAdoptionDepth--; }
    } @catch (NSException *exception) {
        if (!DPCommandPageOwned(page, source)) [page close];
        return completion(NO);
    }
    __weak DPCommandBarLauncher *weak = launcher;
    void (^finish)(BOOL) = ^(BOOL owned) {
        DPCommandBarLauncher *current = weak;
        BOOL opened = owned && DPBrowseSourceUsable(source);
        // Once Dia owns the page, it owns its lifetime; never close an adopted tab during cancellation.
        if (!owned) [page close];
        if (opened && current.launcherEnabled && current.window.visible) [source.window makeKeyAndOrderFront:nil];
        completion(opened);
    };
    if (DPCommandPageOwned(page, source)) return finish(YES);
    __block NSUInteger attempts = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *timer) {
        BOOL owned = DPCommandPageOwned(page, source);
        if (!owned && DPBrowseSourceUsable(source) && weak.launcherEnabled && weak.window.visible && ++attempts < 12) return;
        [timer invalidate]; finish(owned);
    }];
}
