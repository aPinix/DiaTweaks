#import "Launcher.h"

DPMiniLauncher *DPCurrentMiniLauncher;

@implementation DPMiniLauncher
- (void)show {
    self.previousApplication = NSWorkspace.sharedWorkspace.frontmostApplication;
    self.restorePrevious = YES;
    self.source = DPBrowseFrontSource();
    self.suggestions = @[];
    [self buildLauncher];
    [self focus];
    [self query];
    if (self.source) return;
    self.startingSource = YES;
    self.status.stringValue = @"Starting Dia…";
    DPBrowsePrepareSource();
    __weak DPMiniLauncher *weak = self;
    __block NSUInteger polls = 0;
    self.sourceTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
        DPMiniLauncher *launcher = weak;
        if (!launcher) { [timer invalidate]; return; }
        launcher.source = DPBrowseFrontSource();
        if (!launcher.source && ++polls < 100) return;
        [timer invalidate]; launcher.sourceTimer = nil; launcher.startingSource = NO;
        if (launcher.source) { [launcher.window makeKeyAndOrderFront:nil]; [launcher query]; }
        else launcher.status.stringValue = @"Open a Dia window to use its profile";
    }];
}
- (void)query {
    NSUInteger generation = ++self.generation;
    NSString *text = self.search.stringValue;
    NSArray *cached = DPBrowseRecents(self.source);
    if (text.length) cached = [cached filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DPBrowseSuggestion *item, NSDictionary *_) {
        return [item.title localizedCaseInsensitiveContainsString:text] || [item.url.absoluteString localizedCaseInsensitiveContainsString:text];
    }]];
    [self setResults:cached];
    if (!self.source) return;
    __weak DPMiniLauncher *weak = self;
    DPBrowseSuggestions(self.source, text, ^(NSArray<DPBrowseSuggestion *> *native) {
        DPMiniLauncher *launcher = weak;
        if (!launcher || launcher.generation != generation || !launcher.window.visible) return;
        NSMutableArray *merged = [(text.length ? @[] : cached) mutableCopy];
        NSMutableSet *seen = [NSMutableSet new];
        for (DPBrowseSuggestion *item in merged) [seen addObject:item.url.absoluteString];
        for (DPBrowseSuggestion *item in native) if (![seen containsObject:item.url.absoluteString]) {
            [seen addObject:item.url.absoluteString]; [merged addObject:item];
        }
        if (merged.count || !cached.count) [launcher setResults:merged];
    });
}
- (void)controlTextDidChange:(NSNotification *)note { [self query]; }
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    if (selector == @selector(cancelOperation:)) { [self close]; return YES; }
    if (selector == @selector(insertNewline:)) { [self choose:nil]; return YES; }
    NSInteger row = self.table.selectedRow;
    if (selector == @selector(moveDown:)) row = MIN((NSInteger)self.suggestions.count - 1, row + 1);
    else if (selector == @selector(moveUp:)) row = MAX(0, row - 1);
    else return NO;
    if (row >= 0 && row < (NSInteger)self.suggestions.count) [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    return YES;
}
- (void)choose:(id)sender {
    NSInteger row = self.table.selectedRow;
    DPBrowseSuggestion *item = row >= 0 && row < (NSInteger)self.suggestions.count ? self.suggestions[row] : nil;
    NSURL *url = item.url ?: DPBrowseAddress(self.search.stringValue);
    if (!url || !self.source) { NSBeep(); return; }
    self.openingResult = YES;
    DPBrowseWindow *page = DPBrowseOpen(url, self.source, self.window.frame);
    if (!page) {
        self.openingResult = NO; [self setResults:@[]];
        self.status.stringValue = @"Open a Dia window and try again."; return;
    }
    page.returnApplication = self.previousApplication;
    DPBrowseRemember(self.source, url, item.title ?: self.search.stringValue);
    [self close];
}
- (void)windowDidResignKey:(NSNotification *)note {
    if (!self.openingResult && !self.startingSource && !self.presenting) { self.restorePrevious = NO; [self close]; }
}
- (void)windowWillClose:(NSNotification *)note {
    [self closeLauncherShadow];
    self.generation++; [self.sourceTimer invalidate]; self.sourceTimer = nil;
    if (self.activationObserver) [NSNotificationCenter.defaultCenter removeObserver:self.activationObserver];
    self.activationObserver = nil;
    if (DPCurrentMiniLauncher == self) DPCurrentMiniLauncher = nil;
    DPBrowseReleaseSource();
    if (self.restorePrevious && !self.openingResult && self.previousApplication.processIdentifier != NSRunningApplication.currentApplication.processIdentifier)
        [self.previousApplication activateWithOptions:0];
}
- (void)dealloc { [self.sourceTimer invalidate]; }
@end

void DPBrowseShowLauncher(void) {
    if (!DPDiaMini.on) return;
    if (DPCurrentMiniLauncher) {
        [DPCurrentMiniLauncher focus];
        [DPCurrentMiniLauncher.search selectText:nil]; return;
    }
    DPCurrentMiniLauncher = [DPMiniLauncher new]; [DPCurrentMiniLauncher show];
}
void DPBrowseCloseLauncher(void) { [DPCurrentMiniLauncher close]; }
