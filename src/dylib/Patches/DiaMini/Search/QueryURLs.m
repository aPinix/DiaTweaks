#import "Provider.h"

static NSString *const DPQueryMarker = @"DIAQUERYMARKER";
static NSString *DPFormValue(NSURLComponents *parts, NSString *name) {
    for (NSString *pair in [parts.percentEncodedQuery componentsSeparatedByString:@"&"]) {
        NSRange separator = [pair rangeOfString:@"="]; if (separator.location == NSNotFound) continue;
        NSString *key = [[[pair substringToIndex:separator.location] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
        if ([key isEqual:name]) return [[[pair substringFromIndex:NSMaxRange(separator)] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
    }
    return nil;
}
static NSString *DPPattern(NSString *template, NSString *value) {
    if (![template isKindOfClass:NSString.class]) return nil;
    BOOL hasQuery = NO;
    for (NSString *token in @[@"{searchTerms}", @"{searchTerms?}", @"%s"]) {
        if ([template containsString:token]) hasQuery = YES;
        template = [template stringByReplacingOccurrencesOfString:token withString:value];
    }
    return hasQuery ? template : nil;
}
static NSString *DPTemplate(NSString *template, NSString *value) {
    NSString *expanded = DPPattern(template, value);
    return [expanded containsString:@"{"] ? nil : expanded;
}
@implementation DPSiteSearchProvider
- (NSURLComponents *)queryPattern {
    NSString *expanded = DPPattern(self.templateURL, DPQueryMarker);
    NSURLComponents *raw = self.templateURL.length ? [NSURLComponents componentsWithString:self.templateURL] : nil;
    if (!expanded && self.nativeKeyword && [self.host isEqual:@"youtube.com"]
        && (!raw.path.length || [@[@"/", @"/results"] containsObject:raw.path]))
        expanded = @"https://www.youtube.com/results?search_query=DIAQUERYMARKER";
    return expanded.length ? [NSURLComponents componentsWithString:expanded] : nil;
}
- (NSString *)historySearchText {
    NSString *path = self.queryPattern.path;
    NSRange marker = [path rangeOfString:DPQueryMarker];
    if (path && marker.location != NSNotFound) path = [path substringToIndex:marker.location];
    return [(self.host ?: self.keyword) stringByAppendingString:path ?: @""];
}
- (NSString *)host {
    NSString *host = self.homeURL.host.lowercaseString;
    return [host hasPrefix:@"www."] ? [host substringFromIndex:4] : host;
}
- (NSColor *)accent {
    BOOL youtube = [self.host isEqual:@"youtube.com"] || [self.name caseInsensitiveCompare:@"YouTube"] == NSOrderedSame;
    return youtube ? [NSColor colorWithSRGBRed:1 green:0 blue:0 alpha:1] : NSColor.controlAccentColor;
}
- (NSURL *)homeURL {
    NSString *expanded = DPPattern(self.templateURL, DPQueryMarker) ?: self.templateURL;
    NSURLComponents *parts = expanded.length ? [NSURLComponents componentsWithString:expanded] : nil;
    if (!parts.host.length && self.nativeKeyword && [self.keyword containsString:@"."])
        parts = [NSURLComponents componentsWithString:[@"https://" stringByAppendingString:self.keyword]];
    if (!parts.host.length) return nil;
    parts.path = @"/"; parts.query = nil; parts.fragment = nil;
    return DPBrowseURL(parts.URL);
}
- (NSURL *)URLForQuery:(NSString *)query {
    if (!query.length) return nil;
    NSCharacterSet *unreserved = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"];
    NSString *encoded = [query stringByAddingPercentEncodingWithAllowedCharacters:unreserved];
    return DPBrowseURL(DPTemplate(self.templateURL, encoded));
}
- (BOOL)matchesURL:(NSURL *)url {
    NSString *host = url.host.lowercaseString;
    if ([host hasPrefix:@"www."]) host = [host substringFromIndex:4];
    NSURL *home = self.homeURL;
    BOOL samePort = (!home.port && !url.port) || [home.port isEqual:url.port];
    return DPBrowseURL(url) && samePort && self.host.length && [host isEqual:self.host];
}
- (NSString *)queryFromURL:(NSURL *)url {
    if (![self matchesURL:url]) return nil;
    NSURLComponents *pattern = self.queryPattern;
    if (!pattern) return nil;
    NSURLComponents *actual = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    if (![pattern.path containsString:DPQueryMarker] && ![pattern.path isEqual:actual.path]) return nil;
    for (NSURLQueryItem *part in pattern.queryItems) if ([part.value containsString:DPQueryMarker]) {
        NSString *patternValue = DPFormValue(pattern, part.name), *value = DPFormValue(actual, part.name);
        NSRange marker = [patternValue rangeOfString:DPQueryMarker];
        if (marker.location == NSNotFound) return nil;
        NSString *prefix = [patternValue substringToIndex:marker.location], *suffix = [patternValue substringFromIndex:NSMaxRange(marker)];
        if (!value || (prefix.length && ![value hasPrefix:prefix]) || (suffix.length && ![value hasSuffix:suffix]) || value.length < prefix.length + suffix.length) return nil;
        return [value substringWithRange:NSMakeRange(prefix.length, value.length - prefix.length - suffix.length)];
    }
    NSRange marker = [pattern.path rangeOfString:DPQueryMarker];
    if (marker.location == NSNotFound) return nil;
    NSString *prefix = [pattern.path substringToIndex:marker.location], *suffix = [pattern.path substringFromIndex:NSMaxRange(marker)];
    if ((prefix.length && ![actual.path hasPrefix:prefix]) || (suffix.length && ![actual.path hasSuffix:suffix]) || actual.path.length < prefix.length + suffix.length) return nil;
    return [actual.path substringWithRange:NSMakeRange(prefix.length, actual.path.length - prefix.length - suffix.length)];
}
@end
