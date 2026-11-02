#import "BrowserToolbar.h"
#import <objc/message.h>

@implementation DPBrowseWindow (ChromeState)
- (void)prepareNavigationToURL:(NSURL *)url {
    self.pendingURL = url; self.pendingOriginURL = self.contents.url;
    self.pendingSince = NSProcessInfo.processInfo.systemUptime; self.pendingLoadObserved = NO;
    self.address.stringValue = url.absoluteString ?: @"";
}
- (void)updatePage {
    if (self.closing) return;
    id page = self.contents;
    BOOL loading = [page respondsToSelector:@selector(isLoading)] && ((BOOL (*)(id,SEL))objc_msgSend)(page, @selector(isLoading));
    double progress = [page respondsToSelector:@selector(loadProgress)] ? ((double (*)(id,SEL))objc_msgSend)(page, @selector(loadProgress)) : 0;
    NSURL *url = self.contents.url;
    if (loading) self.pendingLoadObserved = YES;
    BOOL committed = url && ![url isEqual:self.pendingOriginURL];
    if (self.pendingURL && (committed || (!loading && (self.pendingLoadObserved || NSProcessInfo.processInfo.systemUptime-self.pendingSince > 2)))) {
        self.pendingURL = self.pendingOriginURL = nil; self.pendingLoadObserved = NO;
    }
    NSURL *display = self.pendingURL ?: url;
    self.address.stringValue = display.absoluteString ?: @"";
    [(DPMiniBrowserAddressPill *)self.addressPill showURL:display loading:loading progress:progress];
    DPMiniBrowserOpenControl *open = (id)self.openControl;
    open.primary.enabled = [self canPromoteToSource:self.source]; open.arrow.enabled = !self.promoting && !self.closing;
    NSString *title = self.contents.title;
    self.window.title = title.length ? [@"Dia Mini — " stringByAppendingString:title] : @"Dia Mini";
    [self layoutBrowserToolbar];
}
- (void)layoutBrowserToolbar {
    CGFloat width = MAX(180, NSWidth(self.window.frame)-270);
    if (self.addressPill.window == self.window && self.openControl.window == self.window) {
        NSRect address = [self.addressPill convertRect:self.addressPill.bounds toView:nil];
        NSRect open = [self.openControl convertRect:self.openControl.bounds toView:nil];
        if (NSMinX(open) > NSMinX(address)) width = MAX(180, floor(NSMinX(open)-NSMinX(address)-12));
    }
    if (fabs(self.addressWidth.constant-width) > 0.5) self.addressWidth.constant = width;
}
@end
