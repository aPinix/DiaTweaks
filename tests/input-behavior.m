#import "Patches/DiaMini/Search/Provider.h"

@interface DPInputMatch : NSObject
@property (strong) NSURL *destinationUrl;
@property (copy) NSString *contents, *matchType, *inlineAutocompleteText, *fillIntoEdit;
@property BOOL allowedToBeDefaultMatch, hasTabMatch;
@end
@implementation DPInputMatch
@end
@interface DPInputBrowser : NSObject
@property BOOL lastPreventInline;
@property (copy) NSString *lastKeyword;
@end
@implementation DPInputBrowser
- (BOOL)autocomplete:(NSString *)text cursorPosition:(int)position preventInlineAutocomplete:(BOOL)prevent startFresh:(BOOL)fresh
             keyword:(NSString *)keyword error:(NSError **)error completion:(void (^)(id))completion {
    self.lastPreventInline = prevent; self.lastKeyword = keyword; completion(@[]); return YES;
}
@end
@interface DPInputEditor : NSTextView
@property BOOL composing;
@end
@implementation DPInputEditor
- (BOOL)hasMarkedText { return self.composing; }
@end
@interface DPInputField : NSTextField
@property (strong) DPInputEditor *editor;
@end
@implementation DPInputField
- (NSText *)currentEditor { return self.editor; }
@end
@interface DPInputLauncher : DPMiniLauncher
@property (copy) NSString *lastRequestedQuery;
@end
@implementation DPInputLauncher
- (void)query {
    self.generation++; self.lastRequestedQuery = [self prepareInputQuery]; self.suppressInlineCompletion = NO;
}
@end

static DPBrowseSuggestion *DPInputChoice(NSString *title, NSString *fill, NSString *url, BOOL search) {
    DPBrowseSuggestion *item = [DPBrowseSuggestion new];
    item.title = title; item.fillIntoEdit = fill; item.url = [NSURL URLWithString:url]; item.searchQuery = search; return item;
}
static void DPInputSet(DPInputLauncher *launcher, NSString *text) {
    DPInputEditor *editor = ((DPInputField *)launcher.search).editor;
    launcher.search.stringValue = text; editor.string = text; editor.selectedRange = NSMakeRange(text.length, 0);
    [launcher userInputDidChange]; [launcher query];
}
static void DPInputBarrier(void) {
    __block BOOL delivered = NO; dispatch_async(dispatch_get_main_queue(), ^{ delivered = YES; });
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:1];
    while (!delivered && deadline.timeIntervalSinceNow > 0) [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    NSCAssert(delivered, @"queued input callbacks were delivered");
}

void DPTestInputBehavior(DPBrowseSource *source) {
    DPInputMatch *match = [DPInputMatch new]; match.contents = @"SwiftVM"; match.matchType = @"history-url";
    match.destinationUrl = [NSURL URLWithString:@"https://swiftvm.app/"]; match.inlineAutocompleteText = @"vm.app";
    match.fillIntoEdit = @"swiftvm.app"; match.allowedToBeDefaultMatch = YES; match.hasTabMatch = YES;
    DPBrowseSuggestion *web = DPBrowseMatches(@[match]).firstObject;
    NSCAssert(web.allowedToBeDefaultMatch && web.hasTabMatch && [web.inlineAutocompleteText isEqual:@"vm.app"]
        && [web.fillIntoEdit isEqual:@"swiftvm.app"], @"native completion and existing-tab metadata survive conversion");
    DPInputBrowser *browser = [DPInputBrowser new]; DPBrowseSource *requestSource = [DPBrowseSource new]; requestSource.browser = browser;
    DPBrowseInputSuggestions(requestSource, @"swift", NO, ^(NSArray *items) {});
    NSCAssert(!browser.lastPreventInline && !browser.lastKeyword.length, @"normal input allows native default completion");
    DPBrowseInputSuggestions(requestSource, @"swift", YES, ^(NSArray *items) {});
    NSCAssert(browser.lastPreventInline, @"deleted or composing input requests native inline suppression");
    DPBrowseKeywordSuggestions(requestSource, @"swift", @"youtube.com", ^(NSArray *items) {});
    NSCAssert(browser.lastPreventInline && [browser.lastKeyword isEqual:@"youtube.com"], @"scoped input preserves its explicit native keyword");

    DPInputLauncher *launcher = [DPInputLauncher new]; launcher.source = source; launcher.suggestions = @[];
    [launcher buildLauncher];
    DPInputField *field = [[DPInputField alloc] initWithFrame:launcher.search.frame];
    field.bordered = NO; field.drawsBackground = NO; field.font = launcher.search.font; field.editor = [DPInputEditor new];
    [launcher.search removeFromSuperview]; launcher.search = field; [launcher.window.contentView addSubview:field];
    [launcher.window makeKeyAndOrderFront:nil];
    DPInputEditor *editor = field.editor;
    DPBrowseSuggestion *literal = DPInputChoice(@"swift", @"swift", @"https://www.google.com/search?q=swift", YES);
    DPBrowseSuggestion *other = DPInputChoice(@"Swiftcord", @"swiftcord.app", @"https://swiftcord.app/", NO);
    NSArray *choices = @[web, literal, other];
    DPInputSet(launcher, @"swift"); [launcher setResults:choices]; [launcher updateInputForResults];
    NSCAssert([field.stringValue isEqual:@"swiftvm.app"] && editor.selectedRange.location == 5 && editor.selectedRange.length == 6
        && [launcher.typedQuery isEqual:@"swift"], @"normal autocomplete selects its suffix without changing the typed query");
    [launcher setResults:@[literal]];
    NSCAssert([field.stringValue isEqual:@"swift"] && !launcher.inputPreview && editor.selectedRange.location == 5
        && !editor.selectedRange.length, @"a later literal default removes the old automatic URL suffix");
    [launcher setResults:choices]; [launcher setResults:@[]];
    NSCAssert([field.stringValue isEqual:@"swift"] && !launcher.inputPreview, @"an empty result update also removes an owned automatic suffix");
    [launcher setResults:choices]; editor.selectedRange = NSMakeRange(0, 0); [launcher setResults:@[literal]];
    NSCAssert([field.stringValue isEqual:@"swiftvm.app"] && editor.selectedRange.location == 0,
        @"an async default change does not overwrite a user-positioned caret");
    DPInputSet(launcher, @"swift"); [launcher setResults:choices]; editor.composing = YES;
    [launcher setResults:@[literal]];
    NSCAssert([field.stringValue isEqual:@"swiftvm.app"] && editor.hasMarkedText,
        @"a default change cannot replace the field editor's active composition");
    editor.composing = NO; DPInputSet(launcher, @"swift"); [launcher setResults:choices];
    [launcher control:field textView:editor doCommandBySelector:@selector(moveDown:)];
    NSCAssert(launcher.table.selectedRow == 1 && [field.stringValue isEqual:@"swift"], @"Down previews the literal search row in the input");
    [launcher control:field textView:editor doCommandBySelector:@selector(moveDown:)];
    NSCAssert(launcher.table.selectedRow == 2 && [field.stringValue isEqual:@"swiftcord.app"], @"the next navigation row previews its destination");
    [launcher query];
    NSCAssert([launcher.lastRequestedQuery isEqual:@"swift"], @"a refresh queries the original input instead of its selected-row preview");
    [launcher setResults:choices];
    NSCAssert(launcher.table.selectedRow == 2 && [field.stringValue isEqual:@"swiftcord.app"], @"same-query reloads preserve explicit keyboard selection");

    DPInputSet(launcher, @"swift");
    editor.composing = YES; [launcher setResults:choices]; [launcher updateInputForResults];
    NSInteger selected = launcher.table.selectedRow;
    NSCAssert([field.stringValue isEqual:@"swift"] && [launcher shouldPreventInlineCompletion]
        && ![launcher control:field textView:editor doCommandBySelector:@selector(moveDown:)]
        && ![launcher control:field textView:editor doCommandBySelector:@selector(cancelOperation:)]
        && launcher.table.selectedRow == selected && launcher.window.visible, @"IME composition owns its text, arrows and Escape");
    editor.composing = NO;
    NSCAssert(![launcher control:field textView:editor doCommandBySelector:@selector(deleteBackward:)], @"the field editor performs the deletion");
    DPInputSet(launcher, @"swift"); [launcher setResults:choices]; [launcher updateInputForResults];
    NSCAssert([field.stringValue isEqual:@"swift"] && [launcher shouldPreventInlineCompletion], @"deletion suppresses asynchronous suffix restoration");
    DPInputSet(launcher, @"swiftt");
    NSCAssert(![launcher shouldPreventInlineCompletion], @"new typing re-enables completion after a deletion");

    DPInputSet(launcher, @"swift"); editor.selectedRange = NSMakeRange(0, 0);
    [launcher setResults:choices]; [launcher updateInputForResults];
    DPInputSet(launcher, @"later"); DPInputBarrier();
    NSCAssert([field.stringValue isEqual:@"later"], @"a deferred completion cannot overwrite a newer input generation");

    DPSiteSearchProvider *youtube = [DPSiteSearchProvider new]; youtube.name = @"YouTube"; youtube.keyword = @"youtube.com";
    youtube.templateURL = @"https://www.youtube.com/results?search_query={searchTerms}";
    launcher.siteProvider = youtube; DPInputSet(launcher, @"draft"); [launcher refreshSiteSearchHeader];
    [launcher setResults:@[DPInputChoice(@"one", @"one", @"https://youtube.com/results?search_query=one", YES),
        DPInputChoice(@"two", @"two", @"https://youtube.com/results?search_query=two", YES)]];
    [launcher control:field textView:editor doCommandBySelector:@selector(moveDown:)];
    NSCAssert(launcher.table.selectedRow == 1 && [field.stringValue isEqual:@"draft"], @"site-search arrows select a query without replacing its input");
    NSCAssert([launcher control:field textView:editor doCommandBySelector:@selector(cancelOperation:)]
        && !launcher.siteProvider && !field.stringValue.length && launcher.window.visible, @"Escape first returns a site search to empty normal input");
    NSCAssert([launcher control:field textView:editor doCommandBySelector:@selector(cancelOperation:)]
        && !launcher.window.visible, @"the next Escape dismisses the launcher");
}
