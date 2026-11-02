#import "BrowserExtensions.h"
#import "BrowserToolbar.h"
#import "WindowCommand.h"
#import <objc/runtime.h>

static char DPMiniExtensionPopoverKey;
NSPopover *DPBrowseMiniExtensionsPopover(DPBrowseWindow *owner) { return owner ? objc_getAssociatedObject(owner,&DPMiniExtensionPopoverKey) : nil; }
void DPBrowseCloseMiniExtensions(DPBrowseWindow *owner) {
    if (!owner) return;
    NSPopover *popover = DPBrowseMiniExtensionsPopover(owner);
    [(DPMiniExtensionList *)popover.contentViewController stopWatchingOwner];
    objc_setAssociatedObject(owner,&DPMiniExtensionPopoverKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    popover.animates = NO; [popover close];
}
NSButton *DPBrowseMiniExtensionsButton(DPBrowseWindow *owner) {
    NSImage *image = [NSImage imageWithSystemSymbolName:@"puzzlepiece.extension" accessibilityDescription:@"Extensions"];
    image = [image imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:16 weight:NSFontWeightRegular]];
    NSButton *button = [NSButton buttonWithImage:image target:owner action:@selector(showMiniExtensions:)];
    button.bordered = NO; button.toolTip = @"Extensions"; button.accessibilityLabel = @"Extensions";
    button.identifier = @"DiaMiniExtensionsButton"; button.frame = NSMakeRect(0,0,26,24); return button;
}

@implementation DPBrowseWindow (Extensions)
- (void)showMiniExtensions:(id)sender {
    if (self.closing || self.promoting || self.transferred || !self.window.visible) return;
    if (DPBrowseMiniExtensionsPopover(self).shown) { DPBrowseCloseMiniExtensions(self); return; }
    [self.destinationPopover close];
    DPMiniWindowCommand *palette = [DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class] ? (id)DPCurrentMiniLauncher : nil;
    if (palette.miniOwner == self) { palette.restorePrevious = NO; [palette close]; }
    NSView *anchor = [sender isKindOfClass:NSView.class] ? sender : nil;
    if (anchor.window != self.window) return;
    DPMiniExtensionList *controller = [DPMiniExtensionList new]; controller.owner = self;
    NSPopover *popover = [NSPopover new]; popover.behavior = NSPopoverBehaviorTransient;
    popover.contentViewController = controller; popover.delegate = controller;
    objc_setAssociatedObject(self,&DPMiniExtensionPopoverKey,popover,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak DPBrowseWindow *weak = self;
    controller.ownerCloseObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification object:self.window queue:nil
        usingBlock:^(NSNotification *note) { DPBrowseCloseMiniExtensions(weak); }];
    @try {
        [popover showRelativeToRect:anchor.bounds ofView:anchor preferredEdge:NSRectEdgeMinY];
        [popover.contentViewController.view.window makeFirstResponder:controller.table];
    } @catch (NSException *exception) { DPBrowseCloseMiniExtensions(self); }
}
@end

@implementation DPMiniExtensionList (Lifecycle)
- (void)stopWatchingOwner {
    if (self.ownerCloseObserver) [NSNotificationCenter.defaultCenter removeObserver:self.ownerCloseObserver];
    self.ownerCloseObserver = nil;
}
- (void)popoverDidClose:(NSNotification *)note {
    [self stopWatchingOwner];
    if (DPBrowseMiniExtensionsPopover(self.owner) == note.object)
        objc_setAssociatedObject(self.owner,&DPMiniExtensionPopoverKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
