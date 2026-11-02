#import "QuickBrowse.h"
#import "WindowCommand.h"
#import <objc/message.h>

@implementation DPBrowseWindow (Navigation)
- (void)navigate:(id)sender {
    NSURL *url = DPBrowseAddress(self.address.stringValue);
    if (!DPBrowseLoadMini(self, url)) NSBeep();
}
- (void)back:(id)sender { [self callNavigation:@selector(goBack)]; }
- (void)forward:(id)sender { [self callNavigation:@selector(goForward)]; }
- (void)reload:(id)sender { [self callNavigation:@selector(reload)]; }
- (void)callNavigation:(SEL)sel {
    if (self.closing || self.promoting || self.transferred) return;
    id (*call)(id, SEL) = (void *)objc_msgSend;
    id nav = self.contents.navigationController;
    if ([nav respondsToSelector:sel]) {
        self.pendingURL = self.pendingOriginURL = nil; self.pendingLoadObserved = NO;
        call(nav, sel); [self updatePage];
    }
}
- (void)promote:(id)sender {
    [self promoteToSource:self.source];
}
@end
