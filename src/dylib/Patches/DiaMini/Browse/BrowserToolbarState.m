#import "BrowserToolbar.h"
#import "BrowserDestinations.h"
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
    NSString *destination = nil;
    for (DPMiniNativeDestination *entry in self.nativeDestinations.entries)
        if (entry.state == NSControlStateValueOn) { destination = entry.title; break; }
    [open setDestinationTitle:destination ?: @"Dia"];
    open.primary.enabled = [self canPromoteToSource:self.source]; open.arrow.enabled = !self.promoting && !self.closing;
    NSString *title = self.contents.title;
    self.window.title = title.length ? [@"Dia Mini — " stringByAppendingString:title] : @"Dia Mini";
    [self layoutBrowserToolbar];
}
- (void)layoutBrowserToolbar {
    self.browserHeader.needsLayout = YES;
}
@end
