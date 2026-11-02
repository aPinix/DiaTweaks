#import "../Search/Provider.h"

@implementation DPMiniLauncher (InputState)
- (NSString *)prepareInputQuery {
    NSString *shown = self.search.stringValue;
    if (self.inputPreview && [shown isEqual:self.inputPreview]) return self.typedQuery ?: shown;
    if (![shown isEqual:self.typedQuery] || self.inputPreview) {
        self.typedQuery = shown; self.inputPreview = nil; self.rowPreviewing = NO;
        self.inputWasDeleted = self.suppressInlineCompletion;
        [self.table deselectAll:nil];
    }
    return self.typedQuery ?: shown;
}
- (void)userInputDidChange {
    if (self.updatingInput) return;
    self.typedQuery = self.search.stringValue; self.inputPreview = nil; self.rowPreviewing = NO;
    self.inputWasDeleted = self.suppressInlineCompletion;
    [self.table deselectAll:nil];
}
- (BOOL)shouldPreventInlineCompletion {
    NSTextView *editor = (id)self.search.currentEditor;
    return self.inputWasDeleted || ([editor isKindOfClass:NSTextView.class] && editor.hasMarkedText);
}
- (BOOL)displayInputPreview:(NSString *)value selectedRange:(NSRange)range {
    NSTextView *editor = (id)self.search.currentEditor;
    if ([editor isKindOfClass:NSTextView.class] && editor.hasMarkedText) return NO;
    self.updatingInput = YES;
    self.inputPreview = value; self.search.stringValue = value;
    if ([editor isKindOfClass:NSTextView.class]) { editor.string = value; editor.selectedRange = range; }
    self.updatingInput = NO;
    return YES;
}
- (void)cancelSiteSearch {
    if (!self.siteProvider) return;
    self.siteProvider = self.siteCandidate = nil; self.siteCompletion = self.siteExitText = nil;
    self.typedQuery = @""; self.inputPreview = nil;
    self.rowPreviewing = self.inputWasDeleted = self.suppressInlineCompletion = NO;
    [self.window makeFirstResponder:self.search];
    [self displayInputPreview:@"" selectedRange:NSMakeRange(0, 0)];
    self.inputPreview = nil;
    [self refreshSiteSearchHeader]; [self query];
}
@end
