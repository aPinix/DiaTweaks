#import "../Search/Provider.h"

DPMiniLauncher *DPCurrentMiniLauncher;

@implementation DPMiniLauncher
- (BOOL)launcherEnabled { return DPDiaMini.on; }
- (void)query {
    if (self.openingResult) return;
    NSUInteger generation = ++self.generation;
    NSString *text = [self prepareSiteSearchQuery];
    if (self.siteProvider) {
        DPSiteSearchProvider *provider = self.siteProvider;
        __weak DPMiniLauncher *weak = self;
        DPBrowseSiteSuggestions(self.source, provider, text, ^(NSArray *items) {
            DPMiniLauncher *launcher = weak;
            if (launcher && launcher.generation == generation && launcher.window.visible && !launcher.openingResult) [launcher setResults:items];
        });
        return;
    }
    NSArray *cached = DPBrowseRecents(self.source);
    if (text.length) cached = [cached filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DPBrowseSuggestion *item, NSDictionary *_) {
        return [item.title localizedCaseInsensitiveContainsString:text] || [item.url.absoluteString localizedCaseInsensitiveContainsString:text];
    }]];
    DPBrowseSuggestion *completed = nil;
    if (self.siteCandidate.homeURL && self.siteCompletion.length) {
        completed = [DPBrowseSuggestion new]; completed.title = self.siteCandidate.name;
        completed.url = self.siteCandidate.homeURL;
        completed.icon = self.siteCandidate.icon;
        completed.fillIntoEdit = self.siteCompletion;
        completed.inlineAutocompleteText = [self.siteCompletion substringFromIndex:MIN(text.length, self.siteCompletion.length)];
        completed.allowedToBeDefaultMatch = YES;
        NSMutableArray *seed = [cached mutableCopy];
        [seed removeObjectsAtIndexes:[seed indexesOfObjectsPassingTest:^BOOL(DPBrowseSuggestion *item, NSUInteger index, BOOL *stop) { return [item.url isEqual:completed.url]; }]];
        [seed insertObject:completed atIndex:0]; cached = seed;
    }
    [self setResults:cached];
    if (!self.source) return;
    __weak DPMiniLauncher *weak = self;
    DPBrowseInputSuggestions(self.source, text, [self shouldPreventInlineCompletion], ^(NSArray<DPBrowseSuggestion *> *native) {
        DPMiniLauncher *launcher = weak;
        if (!launcher || launcher.generation != generation || !launcher.window.visible || launcher.openingResult) return;
        NSMutableArray *merged = [(text.length ? (completed ? @[completed] : @[]) : cached) mutableCopy];
        NSMutableSet *seen = [NSMutableSet new];
        for (DPBrowseSuggestion *item in merged) [seen addObject:item.url.absoluteString];
        for (DPBrowseSuggestion *item in native) if (![seen containsObject:item.url.absoluteString]) {
            [seen addObject:item.url.absoluteString]; [merged addObject:item];
        }
        if (merged.count || !cached.count) [launcher setResults:merged];
    });
}
- (void)controlTextDidChange:(NSNotification *)note {
    if (!self.updatingInput) { [self userInputDidChange]; [self query]; }
}
- (void)choose:(id)sender {
    if (self.openingResult || !self.launcherEnabled) return;
    NSInteger row = self.table.selectedRow;
    DPBrowseSuggestion *item = row >= 0 && row < (NSInteger)self.suggestions.count ? self.suggestions[row] : nil;
    NSURL *url = item.url ?: (self.siteProvider ? [self.siteProvider URLForQuery:self.search.stringValue] : DPBrowseDefaultAddress(self.source, self.search.stringValue));
    if (!url || !self.source) { NSBeep(); return; }
    self.openingResult = YES;
    NSString *title = item.title ?: self.search.stringValue;
    NSString *keyword = self.siteProvider.keyword;
    DPBrowseSource *source = self.source;
    __weak DPMiniLauncher *weak = self;
    [self openURL:url completion:^(BOOL opened) {
        DPMiniLauncher *launcher = weak;
        if (!opened) {
            if (!launcher.launcherEnabled || !launcher.window.visible) return;
            launcher.openingResult = NO; [launcher setResults:@[]];
            launcher.status.stringValue = @"Open a Dia window and try again."; return;
        }
        if (keyword.length) DPBrowseRememberQuery(source, url, title, keyword);
        else DPBrowseRemember(source, url, title);
        [launcher close];
    }];
}
- (void)openURL:(NSURL *)url completion:(void (^)(BOOL))completion {
    DPBrowseWindow *page = DPBrowseOpen(url, self.source, self.window.frame);
    page.returnApplication = self.previousApplication; completion(page != nil);
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
