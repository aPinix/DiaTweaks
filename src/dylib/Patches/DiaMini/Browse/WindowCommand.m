#import "WindowCommand.h"
#import <objc/message.h>

@implementation DPMiniWindowCommand
- (BOOL)launcherEnabled {
    DPBrowseWindow *owner = self.miniOwner;
    return DPDiaMini.on && !DPDiaMini.unavailable && owner && !owner.closing && !owner.promoting
        && !owner.transferred && owner.contents && owner.host.window == owner.window;
}
- (void)buildLauncher {
    [super buildLauncher];
    self.window.title = @"Dia Mini Command Bar"; self.window.identifier = @"DiaTweaks.MiniCommandBar";
    self.window.appearance = self.miniOwner.window.effectiveAppearance;
    self.window.movableByWindowBackground = NO;
    self.window.level = self.miniOwner.window.level; self.shadowWindow.level = self.window.level;
    self.window.collectionBehavior = self.miniOwner.window.collectionBehavior;
    self.search.accessibilityIdentifier = @"DiaMiniCommandSearchField";
    self.closeButton.accessibilityLabel = @"Close Mini Command Bar";
    [self.miniOwner.window addChildWindow:self.window ordered:NSWindowAbove];
    [self watchMiniOwner]; [self installMiniScrim];
}
- (void)openURL:(NSURL *)url completion:(void (^)(BOOL))completion { completion(DPBrowseLoadMini(self.miniOwner, url)); }
- (void)windowWillClose:(NSNotification *)note {
    DPBrowseWindow *owner = self.miniOwner;
    BOOL focus = self.restorePrevious || self.openingResult;
    self.restorePrevious = NO;
    [self stopWatchingMini]; [self removeMiniScrim];
    [self.window.parentWindow removeChildWindow:self.window];
    [super windowWillClose:note];
    if (focus && DPDiaMini.on && !owner.closing && !owner.promoting && !owner.transferred && owner.window.visible) {
        [owner.window makeKeyAndOrderFront:nil]; [owner.window makeFirstResponder:owner.contents.nativeView];
    }
}
- (void)dealloc { [self stopWatchingMini]; [self removeMiniScrim]; }
@end

BOOL DPBrowseLoadMini(DPBrowseWindow *owner, NSURL *url) {
    if (!DPDiaMini.on || !DPBrowseURL(url) || !owner || owner.closing || owner.promoting || owner.transferred || !owner.contents) return NO;
    id navigation = owner.contents.navigationController;
    if (![navigation respondsToSelector:@selector(load:initiatorOrigin:)]) return NO;
    [owner prepareNavigationToURL:url];
    id (*load)(id,SEL,id,id) = (void *)objc_msgSend;
    load(navigation, @selector(load:initiatorOrigin:), url, nil);
    [owner updatePage];
    return !owner.closing && !owner.transferred;
}
