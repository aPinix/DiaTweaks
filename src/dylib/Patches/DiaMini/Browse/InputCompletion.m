#import "../Search/Provider.h"

static BOOL DPOwnsAutomaticSuffix(DPMiniLauncher *launcher, NSTextView *editor, NSString *typed) {
    NSString *shown = launcher.search.stringValue;
    return launcher.inputPreview.length > typed.length && [shown isEqual:launcher.inputPreview]
        && editor.selectedRange.location == typed.length && NSMaxRange(editor.selectedRange) == shown.length;
}

@implementation DPMiniLauncher (InputCompletion)
- (void)updateInputForResults {
    if (self.siteProvider) return;
    if (self.rowPreviewing) { [self previewSelectedInput]; return; }
    [self refreshInputIcon];
    if ([self shouldPreventInlineCompletion]) return;
    NSInteger row = self.table.selectedRow;
    DPBrowseSuggestion *item = row >= 0 && row < (NSInteger)self.suggestions.count ? self.suggestions[row] : nil;
    NSString *typed = self.typedQuery ?: self.search.stringValue;
    NSString *fill = item.inlineAutocompleteText.length ? ([item.fillIntoEdit.lowercaseString hasPrefix:typed.lowercaseString]
        ? item.fillIntoEdit : [typed stringByAppendingString:item.inlineAutocompleteText]) : nil;
    NSTextView *editor = (id)self.search.currentEditor;
    if (![editor isKindOfClass:NSTextView.class] || editor.hasMarkedText) return;
    BOOL completes = typed.length && item.allowedToBeDefaultMatch && item.inlineAutocompleteText.length
        && fill.length > typed.length && [fill.lowercaseString hasPrefix:typed.lowercaseString];
    if (!completes) {
        // A later provider update can replace the automatic URL with a literal search or no results.
        if (DPOwnsAutomaticSuffix(self, editor, typed) && [self displayInputPreview:typed selectedRange:NSMakeRange(typed.length, 0)]) {
            self.inputPreview = nil;
            [self refreshSiteSearchHeader]; [self refreshInputIcon];
        }
        return;
    }
    NSUInteger generation = self.generation;
    __weak DPMiniLauncher *weak = self;
    void (^finish)(void) = ^{
        DPMiniLauncher *launcher = weak;
        if (!launcher || launcher.generation != generation || launcher.siteProvider || launcher.rowPreviewing
            || [launcher shouldPreventInlineCompletion] || launcher.search.currentEditor != editor
            || ![launcher.typedQuery isEqual:typed] || launcher.table.selectedRow != row
            || row >= (NSInteger)launcher.suggestions.count || launcher.suggestions[row] != item) return;
        NSString *shown = launcher.search.stringValue;
        BOOL original = [shown isEqual:typed] && editor.selectedRange.length == 0 && editor.selectedRange.location == typed.length;
        BOOL suffix = DPOwnsAutomaticSuffix(launcher, editor, typed);
        if (!original && !suffix) return;
        [launcher displayInputPreview:fill selectedRange:NSMakeRange(typed.length, fill.length - typed.length)];
        [launcher refreshInputIcon];
    };
    if (editor.selectedRange.location == typed.length) finish();
    else dispatch_async(dispatch_get_main_queue(), finish);
}
@end
