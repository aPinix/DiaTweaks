#import "Patches/DiaMini/Search/Provider.h"

@interface DPSiteFixtureEngine : NSObject
@property (copy) NSString *name, *keyword, *url;
@property NSInteger status;
@end
@implementation DPSiteFixtureEngine
@end
@interface DPSiteFixturePreferences : NSObject
@property (copy) NSArray *engines;
@property (strong) DPSiteFixtureEngine *defaultEngine;
@end
@implementation DPSiteFixturePreferences
- (NSArray *)getSearchEngines { return self.engines ?: @[]; }
- (id)getDefaultSearchEngine { return self.defaultEngine; }
@end
@interface DPSiteFixtureHistory : NSObject
@property (copy) NSArray *items;
@end
@implementation DPSiteFixtureHistory
- (void)searchHistory:(id)options completion:(void (^)(id))completion { completion(self.items ?: @[]); }
@end
@interface DPSiteFixtureContext : NSObject
@property (strong) DPSiteFixturePreferences *preferences;
@property (strong) DPSiteFixtureHistory *history;
@end
@implementation DPSiteFixtureContext
- (instancetype)init {
    if ((self = [super init])) { _preferences = [DPSiteFixturePreferences new]; _history = [DPSiteFixtureHistory new]; }
    return self;
}
@end
@interface DPSiteFixtureBrowser : NSObject
@property (strong) DPSiteFixtureContext *context;
@property (copy) NSArray *matches;
@property (copy) NSString *lastKeyword;
@property (copy) void (^pendingCompletion)(id);
@property NSUInteger autocompleteCalls;
@property BOOL deferAutocomplete;
@end
@implementation DPSiteFixtureBrowser
- (instancetype)init { if ((self = [super init])) _context = [DPSiteFixtureContext new]; return self; }
- (BOOL)autocomplete:(NSString *)text cursorPosition:(int)position preventInlineAutocomplete:(BOOL)prevent startFresh:(BOOL)fresh
             keyword:(NSString *)keyword error:(NSError **)error completion:(void (^)(id))completion {
    self.autocompleteCalls++; self.lastKeyword = keyword;
    if (self.deferAutocomplete) self.pendingCompletion = completion;
    else completion(self.matches ?: @[]);
    return YES;
}
@end

static DPSiteFixtureEngine *DPEngine(NSString *name, NSString *keyword, NSString *url, NSInteger status) {
    DPSiteFixtureEngine *engine = [DPSiteFixtureEngine new];
    engine.name = name; engine.keyword = keyword; engine.url = url; engine.status = status; return engine;
}
static DPSiteSearchProvider *DPProvider(NSString *template) {
    DPSiteSearchProvider *provider = [DPSiteSearchProvider new]; provider.name = @"YouTube";
    provider.keyword = @"youtube.com"; provider.templateURL = template; return provider;
}
static DPBrowseSuggestion *DPHistoryItem(NSURL *url, NSString *title) {
    DPBrowseSuggestion *item = [DPBrowseSuggestion new]; item.url = url; item.title = title; return item;
}
static void DPSiteDrainUntil(BOOL (^ready)(void)) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:1];
    while (!ready() && deadline.timeIntervalSinceNow > 0) [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}
static BOOL DPHasQuery(NSArray<DPBrowseSuggestion *> *items, NSString *query) {
    for (DPBrowseSuggestion *item in items) if ([item.title isEqual:query]) return YES;
    return NO;
}

static void DPTestSiteURLs(void) {
    DPSiteSearchProvider *provider = DPProvider(@"https://www.youtube.com/results?search_query={searchTerms}");
    NSString *query = @"C++ café & a/b?=🚀";
    NSURL *url = [provider URLForQuery:query];
    NSCAssert(url && [url.absoluteString containsString:@"%2B%2B"] && [url.absoluteString containsString:@"%26"]
        && [[provider queryFromURL:url] isEqual:query], @"reserved and Unicode search terms round-trip without becoming URL syntax");
    NSCAssert([[provider queryFromURL:[NSURL URLWithString:@"https://youtube.com/results?search_query=C%2B%2B+tutorial"]] isEqual:@"C++ tutorial"],
        @"form-encoded spaces remain distinct from literal plus signs");
    NSCAssert(![provider queryFromURL:[NSURL URLWithString:@"https://youtube.com/watch?search_query=wrong"]]
        && ![provider queryFromURL:[NSURL URLWithString:@"https://youtube.com.evil.example/results?search_query=wrong"]],
        @"history queries require the provider's host and search path");
    NSCAssert(![provider queryFromURL:[NSURL URLWithString:@"https://youtube.com/results?other=wrong"]]
        && ![provider URLForQuery:@""], @"missing and empty search terms do not create a choice");
    for (NSString *template in @[@"javascript:search({searchTerms})", @"file:///tmp/{searchTerms}",
        @"ftp://example.com/{searchTerms}", @"https://example.com/search", @"https://example.com/{unsupported}?q={searchTerms}"])
        NSCAssert(![DPProvider(template) URLForQuery:@"test"], @"unsafe or unsupported templates are rejected: %@", template);
    for (NSString *template in @[@"https://wiki.example/wiki/%s", @"https://wiki.example/wiki/{searchTerms?}"])
        NSCAssert([[DPProvider(template) queryFromURL:[DPProvider(template) URLForQuery:query]] isEqual:query],
            @"path searches and optional search-term markers round-trip");
    DPSiteSearchProvider *wrapped = DPProvider(@"https://library.example/search?q=prefix+{searchTerms}+suffix");
    NSCAssert([[wrapped queryFromURL:[wrapped URLForQuery:@"one+two"]] isEqual:@"one+two"], @"fixed query affixes are not stored as search terms");
    NSCAssert(![wrapped queryFromURL:[NSURL URLWithString:@"https://library.example/search?q=wrong"]], @"unrelated query values are not accepted");
    DPSiteSearchProvider *native = DPProvider(@"https://www.youtube.com/results?search_query={searchTerms}&ie={inputEncoding}");
    native.nativeKeyword = YES; native.keyword = @"yt";
    NSCAssert([native.host isEqual:@"youtube.com"] && ![native URLForQuery:@"test"]
        && [[native queryFromURL:[NSURL URLWithString:@"https://www.youtube.com/results?search_query=real+history&ie=UTF-8"]] isEqual:@"real history"],
        @"host and query history survive extra native macros without navigating an unresolved template");
    native.templateURL = @"https://www.youtube.com/";
    NSColor *red = [native.accent colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    NSCAssert([native.host isEqual:@"youtube.com"] && red.redComponent > 0.99 && red.greenComponent < 0.01,
        @"provider identity and YouTube branding do not depend on an expandable query template");
    NSCAssert([native.historySearchText isEqual:@"youtube.com/results"]
        && [[native queryFromURL:[NSURL URLWithString:@"https://youtube.com/results?search_query=past+query"]] isEqual:@"past query"],
        @"native homepage-only YouTube providers recover real search history without matching video pages");
    native.templateURL = @"https://youtube.com/@channel";
    NSCAssert(![native queryFromURL:[NSURL URLWithString:@"https://youtube.com/results?search_query=wrong+scope"]],
        @"custom channel scopes do not acquire the whole site's history");
}

static void DPTestSiteProviders(DPBrowseSource *source, DPSiteFixtureBrowser *browser) {
    DPSiteFixtureEngine *library = DPEngine(@"Library", @"papers", @"https://library.example/search?q=%s", 1);
    browser.context.preferences.engines = @[library]; browser.context.preferences.defaultEngine = library;
    NSCAssert([DPSiteSearchProviderForInput(source, @"PAPER").keyword isEqual:@"papers"]
        && [DPSiteSearchProviderForInput(source, @"https://www.library.example/").keyword isEqual:@"papers"],
        @"registered keywords and normalized provider hosts select the same engine");
    NSCAssert(!DPSiteSearchProviderForInput(source, @"") && !DPSiteSearchProviderForInput(source, @"p")
        && !DPSiteSearchProviderForInput(source, @"papers topic"), @"ordinary query text does not accidentally enter a provider scope");
    NSCAssert([DPBrowseDefaultAddress(source, @"search words").host isEqual:@"library.example"], @"plain searches use the source profile's default engine");
    NSURL *explicit = [NSURL URLWithString:@"https://www.google.com/search?q=explicit"];
    NSCAssert([DPBrowseDefaultAddress(source, explicit.absoluteString) isEqual:explicit]
        && [DPBrowseDefaultAddress(source, @"www.google.com").host isEqual:@"www.google.com"], @"an explicit address keeps its intended destination");
    NSCAssert(!DPBrowseDefaultAddress(source, @"javascript:alert(1)"), @"special schemes do not turn into web searches");
    DPSiteFixtureEngine *opaque = DPEngine(@"Google", @"google.com", @"{google:baseURL}search?q={searchTerms}&ie={inputEncoding}", 1);
    browser.context.preferences.engines = @[opaque, library];
    DPSiteSearchProvider *macro = DPSiteSearchProviderForInput(source, @"google");
    NSCAssert([macro.host isEqual:@"google.com"] && macro.nativeKeyword && ![macro URLForQuery:@"macro"],
        @"native engine macros do not crash host discovery or become literal navigation URLs");
    NSCAssert(DPSiteSearchProviderForInput(source, @"you") != nil, @"an opaque native provider does not prevent discovering another site");
    DPBrowseSuggestion *native = DPHistoryItem([NSURL URLWithString:@"https://www.google.com/search?q=macro+result"], @"macro result");
    native.fromKeyword = YES; native.keyword = macro.keyword;
    browser.matches = @[native];
    __block NSArray *macroItems;
    DPBrowseSiteSuggestions(source, macro, @"macro", ^(NSArray *items) { macroItems = items; });
    DPSiteDrainUntil(^BOOL { return DPHasQuery(macroItems, @"macro result"); });
    NSCAssert(DPHasQuery(macroItems, @"macro result"), @"Chromium resolves its own keyword macros without a client-side URL expander");
    browser.matches = @[];
    DPBrowseRememberQuery(source, native.url, @"remembered macro query", macro.keyword);
    DPBrowseSiteSuggestions(source, macro, @"", ^(NSArray *items) { macroItems = items; });
    NSCAssert(DPHasQuery(macroItems, @"remembered macro query"), @"successful native keyword searches retain query metadata for the next launcher");
    DPSiteFixtureEngine *disabled = DPEngine(@"YouTube", @"youtube.com", @"https://www.youtube.com/results?search_query={searchTerms}", 2);
    browser.context.preferences.engines = @[library, disabled];
    NSCAssert(!DPSiteSearchProviderForInput(source, @"youtube.com"), @"a disabled profile provider is not reintroduced as a fallback");
    browser.context.preferences.engines = @[library];
    DPSiteSearchProvider *youtube = DPSiteSearchProviderForInput(source, @"you");
    NSCAssert([youtube.keyword isEqual:@"youtube.com"] && !youtube.nativeKeyword, @"YouTube remains available without modifying profile engine settings");
    DPBrowseSource *other = [DPBrowseSource new]; other.browser = [DPSiteFixtureBrowser new];
    NSCAssert(!DPSiteSearchProviderForInput(other, @"papers"), @"custom providers remain scoped to their source profile");
}

static DPSiteSearchProvider *DPTestSiteSuggestions(DPBrowseSource *source, DPSiteFixtureBrowser *browser) {
    DPSiteSearchProvider *youtube = DPSiteSearchProviderForInput(source, @"you");
    browser.context.history.items = @[
        DPHistoryItem([youtube URLForQuery:@"C++ tutorial"], @"A page title"),
        DPHistoryItem([youtube URLForQuery:@"world landscapes"], @"Another title"),
        DPHistoryItem([NSURL URLWithString:@"https://youtube.com/"], @"YouTube"),
        DPHistoryItem([NSURL URLWithString:@"https://www.google.com/search?q=outside"], @"Outside query")];
    DPBrowseRemember(source, [youtube URLForQuery:@"private A"], @"Source A");
    DPBrowseSource *other = [DPBrowseSource new]; other.browser = [DPSiteFixtureBrowser new];
    DPBrowseRemember(other, [youtube URLForQuery:@"private B"], @"Source B");
    __block NSArray *items;
    DPBrowseSiteSuggestions(source, youtube, @"", ^(NSArray *result) { items = result; });
    DPSiteDrainUntil(^BOOL { return DPHasQuery(items, @"C++ tutorial"); });
    NSCAssert(items.count == 3 && DPHasQuery(items, @"private A") && !DPHasQuery(items, @"private B"),
        @"the scoped recent list combines only matching queries from its source profile");
    NSUInteger before = browser.autocompleteCalls;
    DPBrowseSiteSuggestions(source, youtube, @"trailer", ^(NSArray *result) { items = result; });
    NSCAssert(browser.autocompleteCalls == before && [((DPBrowseSuggestion *)items.firstObject).title isEqual:@"trailer"],
        @"an unregistered fallback keyword does not send site-search text to the default engine");
    youtube.nativeKeyword = YES;
    browser.matches = @[
        DPHistoryItem([youtube URLForQuery:@"trailer hd"], @"Native title"),
        DPHistoryItem([NSURL URLWithString:@"https://www.google.com/search?q=trailer+wrong"], @"Wrong engine")];
    DPBrowseSiteSuggestions(source, youtube, @"trailer", ^(NSArray *result) { items = result; });
    DPSiteDrainUntil(^BOOL { return DPHasQuery(items, @"trailer hd"); });
    NSCAssert([browser.lastKeyword isEqual:youtube.keyword] && items.count == 2
        && [((DPBrowseSuggestion *)items.firstObject).title isEqual:@"trailer"], @"native keyword suggestions merge after the typed site query");
    for (DPBrowseSuggestion *item in items)
        NSCAssert(item.searchQuery && [youtube matchesURL:item.url] && [item.keyword isEqual:youtube.keyword], @"another engine's result never enters the site scope");
    return youtube;
}

static void DPSiteSetText(DPMiniLauncher *launcher, NSString *text) {
    launcher.search.stringValue = text;
    NSTextView *editor = (id)launcher.search.currentEditor;
    if ([editor isKindOfClass:NSTextView.class]) { editor.string = text; editor.selectedRange = NSMakeRange(text.length, 0); }
}
static void DPTestSiteInput(DPBrowseSource *source, DPSiteFixtureBrowser *browser) {
    DPSiteFixtureEngine *youtube = DPEngine(@"YouTube", @"youtube.com", @"https://www.youtube.com/results?search_query={searchTerms}", 1);
    browser.context.preferences.engines = @[youtube];
    DPMiniLauncher *launcher = [DPMiniLauncher new]; launcher.source = source; launcher.suggestions = @[];
    [launcher buildLauncher]; [launcher.window makeKeyAndOrderFront:nil]; [launcher.window makeFirstResponder:launcher.search];
    DPSiteSetText(launcher, @"you"); [launcher query];
    NSTextView *editor = (id)launcher.search.currentEditor;
    NSCAssert(launcher.siteCandidate && !launcher.sitePrompt.hidden && launcher.siteBadge.hidden,
        @"a matching address offers Tab-to-search without entering the site prematurely");
    if ([editor isKindOfClass:NSTextView.class]) NSCAssert([launcher.search.stringValue isEqual:@"youtube.com"]
        && editor.selectedRange.location == 3 && editor.selectedRange.length == 8, @"inline completion selects only the suggested suffix");
    NSCAssert([((DPBrowseSuggestion *)launcher.suggestions.firstObject).url.path isEqual:@"/"],
        @"accepting the completed site address navigates there instead of searching for its incomplete prefix");
    NSCAssert([launcher control:launcher.search textView:editor doCommandBySelector:@selector(insertTab:)]
        && launcher.siteProvider && !launcher.siteBadge.hidden && launcher.sitePrompt.hidden
        && !launcher.search.stringValue.length, @"Tab enters the visible provider scope and clears its query");
    NSCAssert(NSMaxX(launcher.siteBadge.frame) < NSMinX(launcher.search.frame), @"the provider badge leaves the editable query unobstructed");
    browser.deferAutocomplete = YES; DPSiteSetText(launcher, @"stale"); [launcher query];
    void (^stale)(id) = browser.pendingCompletion;
    NSCAssert(stale != nil, @"the scoped query reached native keyword autocomplete");
    browser.deferAutocomplete = NO;
    DPSiteSetText(launcher, @"");
    NSCAssert([launcher control:launcher.search textView:editor doCommandBySelector:@selector(deleteBackward:)]
        && !launcher.siteProvider && [launcher.search.stringValue isEqual:@"youtube.com"], @"Backspace on an empty scoped query restores the provider address");
    NSUInteger generation = launcher.generation;
    DPSiteSearchProvider *provider = DPSiteSearchProviderForInput(source, @"youtube.com");
    stale(@[DPHistoryItem([provider URLForQuery:@"stale result"], @"Stale")]);
    __block BOOL delivered = NO;
    dispatch_async(dispatch_get_main_queue(), ^{ delivered = YES; });
    DPSiteDrainUntil(^BOOL { return delivered; });
    NSCAssert(!launcher.siteProvider && launcher.generation == generation && !DPHasQuery(launcher.suggestions, @"stale result"),
        @"late scoped callbacks cannot replace the normal results after leaving site search");
    [launcher close];
}

void DPTestSiteSearch(DPBrowseSource *source) {
    DPTestSiteURLs();
    DPSiteFixtureBrowser *browser = [DPSiteFixtureBrowser new];
    DPBrowseSource *isolated = [DPBrowseSource new]; isolated.browser = browser; isolated.window = source.window;
    DPTestSiteProviders(isolated, browser);
    DPTestSiteSuggestions(isolated, browser);
    DPTestSiteInput(isolated, browser);
}
