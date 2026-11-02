#import "BrowserToolbar.h"
#import <objc/message.h>

static NSUInteger DPMiniPromotionDepth;
BOOL DPBrowseIsPromoting(void) { return DPMiniPromotionDepth != 0; }
static BOOL DPMiniSameProfile(DPBrowseWindow *owner, DPBrowseSource *source) {
    // ArcBrowser.context returns a fresh wrapper, even for the original browser.
    if (source.browser == owner.source.browser) return YES;
    id context = DPBrowseContext(source), original = owner.profileContext;
    if (context && context == original) return YES;
    id (*get)(id,SEL) = (void *)objc_msgSend;
    if (![context respondsToSelector:@selector(id)] || ![original respondsToSelector:@selector(id)]) return NO;
    id currentID = get(context, @selector(id)), originalID = get(original, @selector(id));
    for (id identity in @[currentID ?: NSNull.null, originalID ?: NSNull.null])
        if (![identity respondsToSelector:@selector(directoryBasename)] || ![identity respondsToSelector:@selector(isIncognito)]) return NO;
    BOOL (*flag)(id,SEL) = (void *)objc_msgSend;
    // Separate private contexts may share a directory. Require the same factory or wrapper for them.
    if (flag(currentID, @selector(isIncognito)) || flag(originalID, @selector(isIncognito))) return NO;
    id current = get(currentID, @selector(directoryBasename)), saved = get(originalID, @selector(directoryBasename));
    return [current isKindOfClass:NSString.class] && [saved isKindOfClass:NSString.class] && [current length] && [current isEqual:saved];
}
BOOL DPBrowseMiniPageAdopted(DPBrowseWindow *owner) {
    id<DPBrowseContents> page = owner.contents;
    if (!page) return NO;
    NSWindow *destination = DPBrowseHost(page).window ?: page.nativeView.window;
    id delegate = DPBrowseDelegate(page);
    return (destination && destination != owner.window) || (delegate && delegate != owner.contentsDelegate);
}

@implementation DPBrowseWindow (OpenPromotion)
- (BOOL)canPromoteToSource:(DPBrowseSource *)source {
    if (self.closing || self.promoting || self.transferred || !self.contents || !DPBrowseSourceUsable(source)) return NO;
    if (!DPMiniSameProfile(self, source)) return NO;
    if (!DPBrowseURL(self.pendingURL ?: self.contents.url)) return NO;
    return [source.browserDelegate respondsToSelector:@selector(browser:didCreateNewWebContents:isActive:)]
        || (source.contents && [source.delegate respondsToSelector:@selector(webContents:didCreateNewWebContent:targetURL:disposition:)]);
}
- (void)promoteToSource:(DPBrowseSource *)source {
    if (![self canPromoteToSource:source]) return (void)NSBeep();
    self.promoting = YES; [self.destinationPopover close]; [self updatePage];
    id<DPBrowseContents> page = self.contents;
    NSURL *url = self.pendingURL ?: page.url;
    [page detachFromPaneHostView:self.host];
    DPMiniPromotionDepth++;
    @try {
        if ([source.browserDelegate respondsToSelector:@selector(browser:didCreateNewWebContents:isActive:)])
            ((void (*)(id,SEL,id,id,BOOL))objc_msgSend)(source.browserDelegate,@selector(browser:didCreateNewWebContents:isActive:),source.browser,page,YES);
        else ((void (*)(id,SEL,id,id,id,NSInteger))objc_msgSend)(source.delegate,@selector(webContents:didCreateNewWebContent:targetURL:disposition:),source.contents,page,url,DPBrowseForegroundTab);
    } @catch (NSException *exception) {
        // A native delegate can adopt before throwing; ownership decides whether rollback is safe.
    } @finally { DPMiniPromotionDepth--; }
    void (^finish)(void) = ^{
        if (self.closing || self.contents != page) return;
        if (DPBrowseMiniPageAdopted(self)) {
            self.transferred = YES;
            if (DPBrowseSourceUsable(source)) [source.window makeKeyAndOrderFront:nil];
            [self close];
        } else {
            self.promoting = NO; [page attachToPaneHostView:self.host];
            [self.window makeKeyAndOrderFront:nil]; [self.window makeFirstResponder:page.nativeView];
            [self updatePage]; NSBeep();
        }
    };
    if (DPBrowseMiniPageAdopted(self)) return finish();
    __block NSUInteger attempts = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *timer) {
        if (!self.closing && DPBrowseSourceUsable(source) && !DPBrowseMiniPageAdopted(self) && ++attempts < 12) return;
        [timer invalidate]; finish();
    }];
}
@end
