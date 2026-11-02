#import "Launcher.h"
#import <objc/message.h>

@implementation DPBrowseSuggestion
- (NSString *)actionLabel { return nil; }
@end

id DPBrowseContext(DPBrowseSource *source) {
    if (DPIsKind(source.browser, DPDiaBrowserContext)) return source.browser;
    id (*get)(id, SEL) = (void *)objc_msgSend;
    return [source.browser respondsToSelector:@selector(context)] ? get(source.browser, @selector(context)) : nil;
}

// Native autocomplete supplies persistent profile history. This fallback is session-only and weakly keyed by
// the source factory: it neither keeps a private context alive nor shares entries with another profile.
static NSMapTable *DPMiniRecentByContext(void) {
    static NSMapTable *map;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ map = [NSMapTable weakToStrongObjectsMapTable]; });
    return map;
}
NSArray<DPBrowseSuggestion *> *DPBrowseRecents(DPBrowseSource *source) {
    id context = source.browser;
    return context ? [[DPMiniRecentByContext() objectForKey:context] copy] ?: @[] : @[];
}
static void DPBrowseStore(DPBrowseSource *source, NSURL *url, NSString *title, NSString *keyword) {
    id context = source.browser;
    if (!context || !DPBrowseURL(url)) return;
    NSMutableArray<DPBrowseSuggestion *> *items = [DPBrowseRecents(source) mutableCopy];
    NSIndexSet *same = [items indexesOfObjectsPassingTest:^BOOL(DPBrowseSuggestion *item, NSUInteger i, BOOL *stop) {
        return [item.url.absoluteString isEqual:url.absoluteString];
    }];
    [items removeObjectsAtIndexes:same];
    DPBrowseSuggestion *item = [DPBrowseSuggestion new]; item.url = url;
    item.title = title.length ? title : url.host;
    item.searchQuery = keyword.length != 0; item.keyword = keyword;
    [items insertObject:item atIndex:0];
    while (items.count > 8) [items removeLastObject];
    [DPMiniRecentByContext() setObject:items forKey:context];
}
void DPBrowseRemember(DPBrowseSource *source, NSURL *url, NSString *title) { DPBrowseStore(source, url, title, nil); }
void DPBrowseRememberQuery(DPBrowseSource *source, NSURL *url, NSString *query, NSString *keyword) {
    DPBrowseStore(source, url, query, keyword);
}
