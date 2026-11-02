#import "OpenTabs.h"
#import <objc/message.h>

static NSHashTable *DPCommandClosedTabs;
static void DPCommandTab_closed(id self, SEL _cmd, id contents, id session) {
    if (contents) [DPCommandClosedTabs addObject:contents];
    DPCallOriginal(DPCommandTab_closed, self, contents, session);
}
void DPCommandBarInstallTabLookup(void) {
    static BOOL installed;
    Class delegate = objc_getClass(DPDiaWebContent);
    SEL closed = @selector(webContents:didCloseWithSessionID:);
    if (installed || !class_getInstanceMethod(delegate, closed)) return;
    DPCommandClosedTabs = [NSHashTable weakObjectsHashTable];
    DPHookClass(delegate, closed, (IMP)DPCommandTab_closed); installed = YES;
}

NSInteger DPCommandBarTabSession(id contents) {
    if (![contents respondsToSelector:@selector(sessionId)]) return 0;
    id (*get)(id, SEL) = (void *)objc_msgSend;
    id session = get(contents, @selector(sessionId));
    if ([session isKindOfClass:NSNumber.class]) return [session integerValue];
    return [session respondsToSelector:@selector(identifier)] ? ((NSInteger (*)(id, SEL))objc_msgSend)(session, @selector(identifier)) : 0;
}

DPBrowseSource *DPCommandBarSourceForTab(id contents, DPBrowseSource *scope) {
    DPCommandBarInstallTabLookup();
    if (!contents || [DPCommandClosedTabs containsObject:contents] || !DPBrowseSourceUsable(scope)) return nil;
    if ([contents respondsToSelector:@selector(isInitialized)] && !((BOOL (*)(id, SEL))objc_msgSend)(contents, @selector(isInitialized))) return nil;
    for (NSView *host = DPBrowseHost(contents); host; host = host.superview)
        if (DPIsKind(host, "DPPeekCard")) return nil;
    DPBrowseSource *candidate = DPBrowseSourceFor(contents);
    // Mini returns its original source; a preview is not a normal tab even when it shares that source's profile.
    if (candidate.contents != contents || candidate.window != scope.window || !DPBrowseSourceUsable(candidate)
        || ![candidate.delegate respondsToSelector:@selector(webContentsSelect:shouldActivate:)]) return nil;
    id context = DPBrowseContext(scope), otherContext = DPBrowseContext(candidate);
    if (candidate.browser != scope.browser && (!context || context != otherContext)) return nil;
    return candidate;
}

BOOL DPCommandBarTabIsCurrent(DPCommandTabSuggestion *tab, DPBrowseSource *source) {
    if (![tab isKindOfClass:DPCommandTabSuggestion.class] || tab.ownerWindow != source.window) return NO;
    id contents = tab.contents;
    if (!DPCommandBarSourceForTab(contents, source)) return NO;
    return tab.sessionIdentifier <= 0 || DPCommandBarTabSession(contents) == tab.sessionIdentifier;
}
