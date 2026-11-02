#import "Provider.h"

static DPBrowseSuggestion *DPQuerySuggestion(DPSiteSearchProvider *provider, NSString *query, NSURL *url) {
    if (!query.length || !url) return nil;
    DPBrowseSuggestion *item = [DPBrowseSuggestion new]; item.title = query; item.url = url;
    item.searchQuery = YES; item.keyword = provider.keyword; return item;
}
static NSArray *DPQueryHistory(DPSiteSearchProvider *provider, NSArray<DPBrowseSuggestion *> *items) {
    NSMutableArray *queries = [NSMutableArray new];
    for (DPBrowseSuggestion *item in items) {
        NSString *text = [provider queryFromURL:item.url];
        if (!text.length && item.searchQuery && [item.keyword isEqual:provider.keyword] && [provider matchesURL:item.url]) text = item.title;
        DPBrowseSuggestion *query = DPQuerySuggestion(provider, text, item.url);
        if (query) [queries addObject:query];
    }
    return queries;
}
void DPBrowseSiteSuggestions(DPBrowseSource *source, DPSiteSearchProvider *provider, NSString *text, void (^completion)(NSArray<DPBrowseSuggestion *> *)) {
    NSArray *cached = DPQueryHistory(provider, DPBrowseRecents(source));
    __block NSArray *history = @[], *native = @[];
    void (^publish)(void) = ^{
        NSMutableArray *merged = [NSMutableArray new]; NSMutableSet *seen = [NSMutableSet new];
        DPBrowseSuggestion *typed = DPQuerySuggestion(provider, text, [provider URLForQuery:text]);
        if (typed) { [merged addObject:typed]; [seen addObject:typed.title.lowercaseString]; }
        for (NSArray *group in @[native, cached, history]) for (DPBrowseSuggestion *item in group) {
            NSString *key = item.title.lowercaseString;
            if ([seen containsObject:key] || (text.length && ![item.title localizedCaseInsensitiveContainsString:text])) continue;
            [seen addObject:key]; [merged addObject:item];
        }
        completion(merged);
    };
    publish();
    if (!source) return;
    DPBrowseHistorySuggestions(source, provider.historySearchText, ^(NSArray *items) {
        history = DPQueryHistory(provider, items); publish();
    });
    if (text.length && provider.nativeKeyword) DPBrowseKeywordSuggestions(source, text, provider.keyword, ^(NSArray *items) {
        // Chromium may ignore an unregistered keyword. Never show another engine's results in a site scope.
        NSMutableArray *scoped = [DPQueryHistory(provider, items) mutableCopy];
        for (DPBrowseSuggestion *item in items) {
            BOOL matches = !item.keyword.length || [item.keyword isEqual:provider.keyword];
            if (!item.isFromKeyword || !matches || (provider.host.length && ![provider matchesURL:item.url])) continue;
            DPBrowseSuggestion *query = DPQuerySuggestion(provider, item.title, item.url);
            if (query) [scoped addObject:query];
        }
        native = scoped; publish();
    });
}
