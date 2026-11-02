#import "QuickBrowse.h"

NSURL *DPBrowseURL(id value) {
    NSURL *url = [value isKindOfClass:NSURL.class] ? value
        : [value isKindOfClass:NSString.class] ? [NSURL URLWithString:value] : nil;
    NSString *scheme = url.scheme.lowercaseString;
    return ([scheme isEqual:@"https"] || [scheme isEqual:@"http"]) && url.host.length ? url : nil;
}

NSURL *DPBrowseAddress(NSString *text) {
    text = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!text.length) return nil;
    NSURL *url = DPBrowseURL(text);
    if (url) return url;
    // Explicit schemes stay explicit. Never turn javascript:, file:, etc. into navigations.
    NSURLComponents *parts = [NSURLComponents componentsWithString:text];
    if (parts.scheme.length) {
        NSRegularExpression *hostPort = [NSRegularExpression regularExpressionWithPattern:@"^(localhost|[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)+):[0-9]+(?:/|$)" options:0 error:nil];
        if (![hostPort firstMatchInString:text options:0 range:NSMakeRange(0, text.length)]) return nil;
    }
    if ([text containsString:@"://"]) return nil;
    if ([text rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location == NSNotFound
        && ([text containsString:@"."] || [text hasPrefix:@"localhost"]))
        return DPBrowseURL([@"https://" stringByAppendingString:text]);
    if (parts.scheme.length) return nil;
    NSURLComponents *search = [NSURLComponents componentsWithString:@"https://www.google.com/search"];
    search.queryItems = @[[NSURLQueryItem queryItemWithName:@"q" value:text]];
    return search.URL;
}

NSRect DPBrowseFrame(NSRect parent, NSRect screen) {
    CGFloat margin = MIN(24, MIN(NSWidth(screen), NSHeight(screen)) / 12);
    NSRect available = NSInsetRect(screen, margin, margin);
    CGFloat width = MIN(1280, MAX(1, NSWidth(available)));
    CGFloat height = MIN(950, MAX(1, NSHeight(available)));
    CGFloat x = NSMidX(parent) - width / 2;
    CGFloat y = NSMidY(parent) - height / 2;
    return NSMakeRect(MAX(NSMinX(available), MIN(x, NSMaxX(available) - width)),
                      MAX(NSMinY(available), MIN(y, NSMaxY(available) - height)), width, height);
}

NSRect DPBrowseLauncherFrame(NSRect screen, CGFloat height) {
    CGFloat margin = MIN(16, MIN(NSWidth(screen), NSHeight(screen)) / 8);
    CGFloat width = MIN(490, MAX(1, NSWidth(screen) - margin * 2));
    height = MIN(height, MAX(1, NSHeight(screen) - margin * 2));
    return NSMakeRect(NSMaxX(screen) - margin - width, NSMaxY(screen) - margin - height, width, height);
}
