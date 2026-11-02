#import "Provider.h"

@implementation DPMiniLauncher (SiteSearch)
- (NSString *)prepareSiteSearchQuery {
    NSString *typed = [self prepareInputQuery];
    self.siteCandidate = self.siteProvider ? nil : DPSiteSearchProviderForInput(self.source, typed);
    [self refreshSiteSearchHeader];
    NSString *completion = [self.siteCandidate.keyword.lowercaseString hasPrefix:typed.lowercaseString] ? self.siteCandidate.keyword : self.siteCandidate.host;
    BOOL matches = typed.length && [completion.lowercaseString hasPrefix:typed.lowercaseString];
    self.siteCompletion = !self.suppressInlineCompletion && !self.siteProvider && matches ? completion : nil;
    self.suppressInlineCompletion = NO;
    return typed;
}
- (void)enterSiteSearch {
    if (!self.siteCandidate || self.siteProvider) return;
    self.siteExitText = [self prepareInputQuery];
    self.siteProvider = self.siteCandidate; self.siteCandidate = nil;
    self.search.stringValue = @"";
    NSTextView *editor = (id)self.search.currentEditor;
    if ([editor isKindOfClass:NSTextView.class]) { editor.string = @""; editor.selectedRange = NSMakeRange(0, 0); }
    [self refreshSiteSearchHeader]; [self query];
}
- (void)leaveSiteSearch {
    NSString *keyword = self.siteExitText ?: self.siteProvider.keyword;
    if (!keyword) return;
    self.siteProvider = nil; self.search.stringValue = keyword;
    self.siteExitText = nil;
    self.typedQuery = keyword; self.inputPreview = nil; self.rowPreviewing = NO;
    self.suppressInlineCompletion = self.inputWasDeleted = YES;
    [self.window makeFirstResponder:self.search];
    NSTextView *editor = (id)self.search.currentEditor;
    if ([editor isKindOfClass:NSTextView.class]) { editor.string = keyword; editor.selectedRange = NSMakeRange(keyword.length, 0); }
    [self query];
}
@end
