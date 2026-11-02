#import "../Search/Provider.h"

static NSString *DPInputFill(DPBrowseSuggestion *item) {
    if (item.fillIntoEdit.length) return item.fillIntoEdit;
    if (item.searchQuery) return item.title;
    NSString *value = item.url.absoluteString;
    for (NSString *prefix in @[@"https://", @"http://"])
        if ([value.lowercaseString hasPrefix:prefix]) { value = [value substringFromIndex:prefix.length]; break; }
    if ([item.url.path isEqual:@"/"] && !item.url.query.length && !item.url.fragment.length && [value hasSuffix:@"/"])
        value = [value substringToIndex:value.length - 1];
    return value;
}
@implementation DPMiniLauncher (InputPreview)
- (void)previewSelectedInput {
    if (self.siteProvider) return;
    NSInteger row = self.table.selectedRow;
    if (row < 0 || row >= (NSInteger)self.suggestions.count) return;
    NSString *value = DPInputFill(self.suggestions[row]);
    if (!value.length) return;
    if (!self.typedQuery) self.typedQuery = self.search.stringValue;
    if (![self displayInputPreview:value selectedRange:NSMakeRange(value.length, 0)]) return;
    self.rowPreviewing = YES;
    self.siteCandidate = DPSiteSearchProviderForInput(self.source, value);
    self.siteCompletion = nil;
    [self refreshSiteSearchHeader];
    [self refreshInputIcon];
}
- (void)refreshInputIcon {
    if (self.siteProvider) return;
    NSInteger row = self.table.selectedRow;
    if (row < 0 || row >= (NSInteger)self.suggestions.count) return;
    DPBrowseSuggestion *item = self.suggestions[row];
    BOOL preview = self.rowPreviewing || self.inputPreview.length
        || (item.allowedToBeDefaultMatch && [item.fillIntoEdit isEqual:self.search.stringValue]);
    if (!preview) return;
    NSImage *image = item.searchQuery ? nil : item.icon ?: self.siteCandidate.icon;
    self.searchIcon.image = image ?: [NSImage imageWithSystemSymbolName:item.searchQuery ? @"magnifyingglass" : @"globe" accessibilityDescription:item.searchQuery ? @"Search" : nil];
    self.searchIcon.contentTintColor = image ? nil : NSColor.labelColor;
}
@end
