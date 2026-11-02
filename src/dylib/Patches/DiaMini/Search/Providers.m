#import "Provider.h"
#import <objc/message.h>

static id DPRead(id object, SEL selector) {
    id (*get)(id, SEL) = (void *)objc_msgSend;
    return [object respondsToSelector:selector] ? get(object, selector) : nil;
}
static NSString *DPHostInput(NSString *text) {
    text = text.lowercaseString;
    for (NSString *prefix in @[@"https://", @"http://", @"www.", @"@"])
        if ([text hasPrefix:prefix]) text = [text substringFromIndex:prefix.length];
    return [text hasSuffix:@"/"] ? [text substringToIndex:text.length - 1] : text;
}
NSArray<DPSiteSearchProvider *> *DPSiteSearchProviders(DPBrowseSource *source) {
    id preferences = DPRead(DPBrowseContext(source), @selector(preferences));
    id engines = DPRead(preferences, @selector(getSearchEngines));
    NSMutableArray *providers = [NSMutableArray new]; NSMutableSet *seen = [NSMutableSet new];
    BOOL knowsYouTube = NO;
    for (id engine in [engines isKindOfClass:NSArray.class] ? engines : @[]) {
        NSString *name = DPRead(engine, @selector(name)), *keyword = DPRead(engine, @selector(keyword)), *url = DPRead(engine, @selector(url));
        if (![name isKindOfClass:NSString.class] || ![keyword isKindOfClass:NSString.class] || !keyword.length || ![url isKindOfClass:NSString.class]) continue;
        DPSiteSearchProvider *provider = [DPSiteSearchProvider new]; provider.name = name; provider.keyword = keyword; provider.templateURL = url;
        provider.nativeKeyword = YES;
        if ([provider.host isEqual:@"youtube.com"]) knowsYouTube = YES;
        NSInteger (*status)(id, SEL) = (void *)objc_msgSend;
        if (([engine respondsToSelector:@selector(status)] && status(engine, @selector(status)) == 2) || [seen containsObject:keyword.lowercaseString]) continue;
        [seen addObject:keyword.lowercaseString]; [providers addObject:provider];
    }
    // Arc includes YouTube site search out of the box. Do not override a disabled profile provider.
    if (!knowsYouTube) {
        DPSiteSearchProvider *youtube = [DPSiteSearchProvider new]; youtube.name = @"YouTube"; youtube.keyword = @"youtube.com";
        youtube.templateURL = @"https://www.youtube.com/results?search_query={searchTerms}"; [providers addObject:youtube];
    }
    return providers;
}
DPSiteSearchProvider *DPSiteSearchProviderForInput(DPBrowseSource *source, NSString *input) {
    NSString *normalized = DPHostInput([input stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]);
    if (normalized.length < 2 || [normalized rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location != NSNotFound) return nil;
    DPSiteSearchProvider *prefix = nil;
    for (DPSiteSearchProvider *provider in DPSiteSearchProviders(source)) {
        NSString *keyword = DPHostInput(provider.keyword);
        if ([keyword isEqual:normalized] || [provider.host isEqual:normalized]) return provider;
        if (!prefix && ([keyword hasPrefix:normalized] || [provider.name.lowercaseString hasPrefix:normalized])) prefix = provider;
    }
    return prefix;
}
NSURL *DPBrowseDefaultAddress(DPBrowseSource *source, NSString *text) {
    NSURL *address = DPBrowseAddress(text);
    if (!address || ![address.host isEqual:@"www.google.com"]) return address;
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL words = [trimmed rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location != NSNotFound;
    if (DPBrowseURL(trimmed) || (!words && ([trimmed containsString:@"."] || [trimmed hasPrefix:@"localhost"]))) return address;
    id preferences = DPRead(DPBrowseContext(source), @selector(preferences));
    id engine = DPRead(preferences, @selector(getDefaultSearchEngine));
    DPSiteSearchProvider *provider = [DPSiteSearchProvider new]; provider.templateURL = DPRead(engine, @selector(url));
    return [provider URLForQuery:text] ?: address;
}
