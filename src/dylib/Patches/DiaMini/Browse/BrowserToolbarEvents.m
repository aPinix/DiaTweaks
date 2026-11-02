#import "BrowserToolbar.h"
#import "WindowCommand.h"

@implementation DPBrowseWindow (AddressActions)
- (void)editAddress:(id)sender { DPBrowseEditMini(self, YES); }
- (NSString *)browserURLString { return (self.pendingURL ?: self.contents.url).absoluteString ?: self.address.stringValue; }
- (void)copyLink:(id)sender {
    NSString *url = [self browserURLString]; if (!url.length) return;
    [NSPasteboard.generalPasteboard clearContents];
    [NSPasteboard.generalPasteboard setString:url forType:NSPasteboardTypeString];
}
@end

@implementation DPBrowseWindow (ToolbarWindowEvents)
- (void)windowDidResize:(NSNotification *)note { [self layoutBrowserToolbar]; }
- (void)windowDidEndLiveResize:(NSNotification *)note { DPBrowseSaveMiniSize(self.window); }
@end
