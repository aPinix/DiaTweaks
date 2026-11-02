#import "OpenTabs.h"

@implementation DPCommandBarLauncher (Suggestions)
- (void)setResults:(NSArray<DPBrowseSuggestion *> *)results {
    if (self.siteProvider) return [super setResults:results];
    NSArray<DPCommandTabSuggestion *> *tabs = DPCommandBarMatchingTabs(self.source, self.typedQuery ?: self.search.stringValue);
    if (!tabs.count) return [super setResults:results];
    NSMutableArray *merged = [tabs mutableCopy];
    NSMutableSet *seen = [NSMutableSet new];
    for (DPCommandTabSuggestion *tab in tabs) {
        [seen addObject:tab.url.absoluteString];
        for (DPBrowseSuggestion *item in results) if ([item.url isEqual:tab.url]) {
            tab.icon = item.icon;
            tab.fillIntoEdit = item.fillIntoEdit; tab.inlineAutocompleteText = item.inlineAutocompleteText;
            tab.allowedToBeDefaultMatch = item.allowedToBeDefaultMatch;
            break;
        }
        NSString *typed = self.typedQuery ?: @"", *fill = tab.fillIntoEdit.length ? tab.fillIntoEdit : tab.url.absoluteString;
        if (!tab.fillIntoEdit.length && ![fill.lowercaseString hasPrefix:typed.lowercaseString])
            for (NSString *prefix in @[@"https://", @"http://", @"www."])
                if ([fill.lowercaseString hasPrefix:prefix]) fill = [fill substringFromIndex:prefix.length];
        if ([tab.url.path isEqual:@"/"] && !tab.url.query.length && !tab.url.fragment.length && [fill hasSuffix:@"/"])
            fill = [fill substringToIndex:fill.length - 1];
        if (!tab.fillIntoEdit.length && typed.length && [fill.lowercaseString hasPrefix:typed.lowercaseString]) {
            tab.fillIntoEdit = fill; tab.inlineAutocompleteText = [fill substringFromIndex:typed.length];
            tab.allowedToBeDefaultMatch = YES;
        }
    }
    for (DPBrowseSuggestion *item in results) if (![seen containsObject:item.url.absoluteString]) {
        [seen addObject:item.url.absoluteString]; [merged addObject:item];
    }
    [super setResults:merged];
}
@end
