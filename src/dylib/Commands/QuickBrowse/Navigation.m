#import "QuickBrowse.h"
#import <objc/message.h>

@implementation DPBrowseWindow (Navigation)
- (void)navigate:(id)sender {
    NSURL *url = DPBrowseAddress(self.address.stringValue);
    if (!url) return (void)NSBeep();
    id (*load)(id, SEL, id, id) = (void *)objc_msgSend;
    load(self.contents.navigationController, @selector(load:initiatorOrigin:), url, nil);
    [self.window makeFirstResponder:self.host];
}
- (void)back:(id)sender { [self callNavigation:@selector(goBack)]; }
- (void)forward:(id)sender { [self callNavigation:@selector(goForward)]; }
- (void)reload:(id)sender { [self callNavigation:@selector(reload)]; }
- (void)callNavigation:(SEL)sel {
    id (*call)(id, SEL) = (void *)objc_msgSend;
    id nav = self.contents.navigationController;
    if ([nav respondsToSelector:sel]) call(nav, sel);
}
- (void)promote:(id)sender {
    id source = self.source.contents, delegate = self.source.delegate;
    if (!DPBrowseSourceUsable(self.source) || !self.contents || self.transferred) return (void)NSBeep();
    NSURL *url = DPBrowseURL(self.contents.url);
    if (!url) return (void)NSBeep();
    // Give Dia the existing contents, preserving its navigation stack and form state.
    // The source delegate is Dia's own tab-opening path, so this stays in the same profile.
    id<DPBrowseContents> contents = self.contents;
    [contents detachFromPaneHostView:self.host];
    void (*open)(id, SEL, id, id, id, NSInteger) = (void *)objc_msgSend;
    if (source && delegate) open(delegate, @selector(webContents:didCreateNewWebContent:targetURL:disposition:), source, contents, url, DPBrowseForegroundTab);
    else {
        void (*adopt)(id,SEL,id,id,BOOL) = (void *)objc_msgSend;
        adopt(self.source.browserDelegate,@selector(browser:didCreateNewWebContents:isActive:),self.source.browser,contents,YES);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 2), dispatch_get_main_queue(), ^{
        if (self.closing) return;
        NSWindow *destination = DPBrowseHost(contents).window ?: contents.nativeView.window;
        if ((destination && destination != self.window)
            || (DPBrowseDelegate(contents) && DPBrowseDelegate(contents) != self.contentsDelegate)) {
            self.transferred = YES;
            [self.source.window makeKeyAndOrderFront:nil];
            [self close];
        } else {
            [contents attachToPaneHostView:self.host];
            NSBeep();
        }
    });
}
@end
