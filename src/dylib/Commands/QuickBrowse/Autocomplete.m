#import "Launcher.h"
#import <objc/message.h>

static id DPCompletionValue(id object, SEL selector) {
    id (*get)(id, SEL) = (void *)objc_msgSend;
    return [object respondsToSelector:selector] ? get(object, selector) : nil;
}

NSArray<DPBrowseSuggestion *> *DPBrowseMatches(id result) {
    NSArray *matches = [result isKindOfClass:NSArray.class] ? result : DPCompletionValue(result, @selector(combinedMatches));
    if (![matches isKindOfClass:NSArray.class]) return @[];
    NSMutableArray *items = [NSMutableArray new]; NSMutableSet *seen = [NSMutableSet new];
    for (id match in matches) {
        NSURL *url = DPBrowseURL(DPCompletionValue(match, @selector(destinationUrl)))
            ?: DPBrowseURL(DPCompletionValue(match, @selector(destinationUrlSpec)))
            ?: DPBrowseURL(DPCompletionValue(match, @selector(url)))
            ?: DPBrowseURL(DPCompletionValue(match, @selector(urlSpec)));
        if (!url || [seen containsObject:url.absoluteString]) continue;
        [seen addObject:url.absoluteString];
        DPBrowseSuggestion *item = [DPBrowseSuggestion new]; item.url = url;
        id title = DPCompletionValue(match, @selector(contents)) ?: DPCompletionValue(match, @selector(title));
        id detail = DPCompletionValue(match, @selector(description));
        BOOL (*flag)(id, SEL) = (void *)objc_msgSend;
        if ([match respondsToSelector:@selector(swapContentsAndDescription)] && flag(match, @selector(swapContentsAndDescription))
            && [detail isKindOfClass:NSString.class] && [detail length]) title = detail;
        item.title = [title isKindOfClass:NSString.class] && [title length] ? title : url.host;
        [items addObject:item];
        if (items.count == 6) break;
    }
    return items;
}

static BOOL DPBrowseHistory(DPBrowseSource *source, NSString *text, void (^completion)(NSArray<DPBrowseSuggestion *> *)) {
    id history = DPCompletionValue(DPBrowseContext(source), @selector(history));
    Class optionsClass = objc_getClass(DPDiaHistoryQueryOptions);
    if (!optionsClass || ![history respondsToSelector:@selector(searchHistory:completion:)]) return NO;
    id options = [optionsClass new];
    void (*setText)(id,SEL,id) = (void *)objc_msgSend;
    void (*setCount)(id,SEL,int) = (void *)objc_msgSend;
    setText(options,@selector(setSearchText:),text); setCount(options,@selector(setMaxResults:),8);
    void (*query)(id,SEL,id,void (^)(id)) = (void *)objc_msgSend;
    query(history,@selector(searchHistory:completion:),options,^(id results) {
        NSArray *items=DPBrowseMatches(results);
        dispatch_async(dispatch_get_main_queue(),^{ completion(items); });
    });
    return YES;
}

void DPBrowseSuggestions(DPBrowseSource *source, NSString *text, void (^completion)(NSArray<DPBrowseSuggestion *> *)) {
    if (!text.length && DPBrowseHistory(source,text,completion)) return;
    id owner = DPBrowseAutocompleteOwner(source);
    SEL selector = @selector(autocomplete:cursorPosition:preventInlineAutocomplete:startFresh:keyword:error:completion:);
    if (![owner respondsToSelector:selector]) {
        if (!DPBrowseHistory(source,text,completion)) completion(@[]);
        return;
    }
    BOOL (*query)(id, SEL, NSString *, int, BOOL, BOOL, NSString *, NSError **, void (^)(id)) = (void *)objc_msgSend;
    NSError *error;
    BOOL started = query(owner, selector, text, (int)MIN(text.length, INT_MAX), YES, text.length == 0, nil, &error, ^(id result) {
        NSArray *items = DPBrowseMatches(result);
        dispatch_async(dispatch_get_main_queue(), ^{ completion(items); });
    });
    if (!started) completion(@[]);
}
