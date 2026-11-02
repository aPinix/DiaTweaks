#import "OpenTabs.h"

@interface DPCommandTabSuggestion ()
@property (weak, readwrite) id contents;
@property (weak, readwrite) NSWindow *ownerWindow;
@property (readwrite) NSInteger sessionIdentifier;
@end
@implementation DPCommandTabSuggestion
- (NSString *)actionLabel { return @"Switch to Tab"; }
@end

static NSInteger DPCommandTabRank(DPCommandTabSuggestion *tab, NSString *query) {
    NSString *host = tab.url.host.lowercaseString ?: @"", *title = tab.title.lowercaseString ?: @"";
    if ([host isEqual:query] || [title isEqual:query] || [tab.url.absoluteString.lowercaseString isEqual:query]) return 0;
    return [host hasPrefix:query] || [title hasPrefix:query] ? 1 : 2;
}

NSArray<DPCommandTabSuggestion *> *DPCommandBarMatchingTabs(DPBrowseSource *source, NSString *query) {
    if (!DPBrowseSourceUsable(source)) return @[];
    NSString *text = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    NSMutableArray<DPCommandTabSuggestion *> *matches = [NSMutableArray new];
    for (id<DPBrowseContents> contents in DPBrowseKnownContents()) {
        DPBrowseSource *candidate = DPCommandBarSourceForTab(contents, source);
        if (!candidate) continue;
        NSURL *url = DPBrowseURL(contents.url); if (!url) continue;
        NSString *title = contents.title.length ? contents.title : url.host;
        if (text.length && ![title localizedCaseInsensitiveContainsString:text] && ![url.absoluteString localizedCaseInsensitiveContainsString:text]) continue;
        DPCommandTabSuggestion *tab = [DPCommandTabSuggestion new];
        tab.contents = contents; tab.ownerWindow = candidate.window; tab.sessionIdentifier = DPCommandBarTabSession(contents);
        tab.url = url; tab.title = title; [matches addObject:tab];
    }
    NSString *lowercase = text.lowercaseString;
    [matches sortUsingComparator:^NSComparisonResult(DPCommandTabSuggestion *a, DPCommandTabSuggestion *b) {
        NSInteger first = DPCommandTabRank(a, lowercase), second = DPCommandTabRank(b, lowercase);
        if (first != second) return first < second ? NSOrderedAscending : NSOrderedDescending;
        BOOL activeA = a.contents == source.contents, activeB = b.contents == source.contents;
        if (activeA != activeB) return activeA ? NSOrderedAscending : NSOrderedDescending;
        NSComparisonResult title = [a.title localizedStandardCompare:b.title];
        if (title != NSOrderedSame) return title;
        return a.sessionIdentifier == b.sessionIdentifier ? NSOrderedSame : a.sessionIdentifier < b.sessionIdentifier ? NSOrderedAscending : NSOrderedDescending;
    }];
    return matches;
}
