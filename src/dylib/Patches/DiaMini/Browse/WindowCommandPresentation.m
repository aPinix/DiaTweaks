#import "WindowCommand.h"
#import "../Search/Provider.h"
#import "BrowserExtensions.h"
#import "BrowserToolbar.h"

DPBrowseWindow *DPBrowseMiniForWindow(NSWindow *window) {
    if (!window) return nil;
    for (DPBrowseWindow *owner in DPBrowseWindows) if (!owner.closing && (owner.window == window
        || (owner.destinationPopover.shown && owner.destinationPopover.contentViewController.view.window == window)
        || (DPBrowseMiniExtensionsPopover(owner).shown && DPBrowseMiniExtensionsPopover(owner).contentViewController.view.window == window))) return owner;
    if ([DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class] && DPCurrentMiniLauncher.window == window)
        return ((DPMiniWindowCommand *)DPCurrentMiniLauncher).miniOwner;
    return nil;
}

void DPBrowseEditMini(DPBrowseWindow *owner, BOOL prefill) {
    if (!DPDiaMini.on || DPDiaMini.unavailable || !owner || owner.closing || owner.promoting || owner.transferred || !owner.contents) return;
    // Finish the popup's key-window transition before focusing a new palette.
    [owner.destinationPopover close];
    DPBrowseCloseMiniExtensions(owner);
    DPMiniWindowCommand *current = [DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class] ? (id)DPCurrentMiniLauncher : nil;
    if (current.miniOwner == owner && current.window.visible) {
        [current focus];
        if (prefill) [current prefillMiniAddress];
        else {
            current.siteProvider = current.siteCandidate = nil; current.siteCompletion = current.siteExitText = nil;
            current.typedQuery = @""; current.inputPreview = nil;
            current.rowPreviewing = current.inputWasDeleted = current.suppressInlineCompletion = NO;
            [current displayInputPreview:@"" selectedRange:NSMakeRange(0, 0)]; current.inputPreview = nil;
            [current query];
        }
        return;
    }
    DPMiniLauncher *previous = DPCurrentMiniLauncher;
    DPMiniWindowCommand *palette = [DPMiniWindowCommand new]; palette.miniOwner = owner; palette.source = owner.source;
    DPCurrentMiniLauncher = palette;
    previous.restorePrevious = NO; [previous close];
    [palette show];
    if (prefill) [palette prefillMiniAddress];
}

@implementation DPMiniWindowCommand (Input)
- (void)prefillMiniAddress {
    NSString *address = DPBrowseURL(self.miniOwner.address.stringValue).absoluteString
        ?: DPBrowseURL(self.miniOwner.contents.url).absoluteString ?: @"";
    self.siteProvider = self.siteCandidate = nil; self.siteCompletion = self.siteExitText = nil;
    self.inputPreview = nil; self.rowPreviewing = NO; self.typedQuery = address;
    self.suppressInlineCompletion = self.inputWasDeleted = YES;
    self.updatingInput = YES; self.search.stringValue = address;
    [self.window makeFirstResponder:self.search];
    NSTextView *editor = (id)self.search.currentEditor;
    if ([editor isKindOfClass:NSTextView.class]) { editor.string = address; editor.selectedRange = NSMakeRange(0, address.length); }
    self.updatingInput = NO;
    [self refreshSiteSearchHeader]; [self query]; [self.search selectText:nil];
}
@end
