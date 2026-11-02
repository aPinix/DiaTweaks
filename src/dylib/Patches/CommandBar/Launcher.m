#import "CommandBar.h"
#import "OpenTabs.h"

@implementation DPCommandBarLauncher
- (BOOL)launcherEnabled { return DPCommandBar.on && !DPCommandBar.unavailable; }
- (void)buildLauncher {
    [super buildLauncher];
    self.window.title = @"Command Bar"; self.window.identifier = @"DiaTweaks.CommandBar";
    [self trackSourceWindow];
}
- (void)openURL:(NSURL *)url completion:(void (^)(BOOL))completion { DPCommandBarOpenTab(self, url, completion); }
- (void)choose:(id)sender {
    NSInteger row = self.table.selectedRow;
    DPBrowseSuggestion *item = row >= 0 && row < (NSInteger)self.suggestions.count ? self.suggestions[row] : nil;
    if (![item isKindOfClass:DPCommandTabSuggestion.class]) return [super choose:sender];
    if (self.openingResult || !self.launcherEnabled) return;
    self.openingResult = YES;
    if (DPCommandBarActivateTab((DPCommandTabSuggestion *)item, self.source)) { self.restorePrevious = NO; [self close]; }
    else { self.openingResult = NO; [self query]; }
}
- (void)windowWillClose:(NSNotification *)note {
    for (id observer in @[self.sourceResizeObserver ?: NSNull.null, self.sourceCloseObserver ?: NSNull.null])
        if (observer != NSNull.null) [NSNotificationCenter.defaultCenter removeObserver:observer];
    self.sourceResizeObserver = self.sourceCloseObserver = nil;
    [self.window.parentWindow removeChildWindow:self.window];
    [super windowWillClose:note];
}
@end

void DPCommandBarShow(void) {
    if (!DPCommandBar.on || DPCommandBar.unavailable) return;
    if (DPCurrentMiniLauncher.commandBar && DPCurrentMiniLauncher.window.visible) {
        [DPCurrentMiniLauncher focus]; [DPCurrentMiniLauncher.search selectText:nil]; return;
    }
    DPMiniLauncher *previous = DPCurrentMiniLauncher;
    DPCommandBarLauncher *launcher = [DPCommandBarLauncher new]; launcher.commandBar = YES;
    launcher.source = DPBrowseSourceUsable(previous.source) ? previous.source : DPBrowseFrontSource();
    DPCurrentMiniLauncher = launcher;
    previous.restorePrevious = NO; [previous close]; [launcher show];
}
void DPCommandBarClose(void) { if (DPCurrentMiniLauncher.commandBar) [DPCurrentMiniLauncher close]; }
