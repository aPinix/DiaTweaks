#import "../Search/Provider.h"

@implementation DPMiniLauncher (Input)
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    if (textView.hasMarkedText) return NO;
    if (selector == @selector(cancelOperation:)) {
        if (self.siteProvider) [self cancelSiteSearch];
        else [self close];
        return YES;
    }
    if (selector == @selector(insertNewline:)) { [self choose:nil]; return YES; }
    if (selector == @selector(insertTab:) && self.siteCandidate && !self.siteProvider) { [self enterSiteSearch]; return YES; }
    if (selector == @selector(deleteBackward:)) {
        if (self.siteProvider && !self.search.stringValue.length) { [self leaveSiteSearch]; return YES; }
        self.suppressInlineCompletion = self.inputWasDeleted = YES; return NO;
    }
    if ([NSStringFromSelector(selector) hasPrefix:@"delete"]) { self.suppressInlineCompletion = self.inputWasDeleted = YES; return NO; }
    NSInteger row = self.table.selectedRow;
    if (selector == @selector(moveDown:)) row = MIN((NSInteger)self.suggestions.count - 1, row + 1);
    else if (selector == @selector(moveUp:)) row = MAX(0, row - 1);
    else return NO;
    if (row >= 0 && row < (NSInteger)self.suggestions.count) {
        [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [self previewSelectedInput];
    }
    return YES;
}
@end
