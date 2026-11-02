#import "../Browse/Launcher.h"

@interface DPSiteSearchProvider : NSObject
@property (copy) NSString *name, *keyword, *templateURL;
@property (strong) NSImage *icon;
@property BOOL nativeKeyword;
@property (readonly) NSString *host;
@property (readonly) NSURL *homeURL;
@property (readonly) NSColor *accent;
@property (readonly) NSString *historySearchText;
- (NSURL *)URLForQuery:(NSString *)query;
- (NSString *)queryFromURL:(NSURL *)url;
- (BOOL)matchesURL:(NSURL *)url;
@end

NSArray<DPSiteSearchProvider *> *DPSiteSearchProviders(DPBrowseSource *source);
DPSiteSearchProvider *DPSiteSearchProviderForInput(DPBrowseSource *source, NSString *input);
void DPBrowseSiteSuggestions(DPBrowseSource *source, DPSiteSearchProvider *provider, NSString *text,
    void (^completion)(NSArray<DPBrowseSuggestion *> *));
void DPBrowseKeywordSuggestions(DPBrowseSource *source, NSString *text, NSString *keyword,
    void (^completion)(NSArray<DPBrowseSuggestion *> *));
void DPBrowseHistorySuggestions(DPBrowseSource *source, NSString *text, void (^completion)(NSArray<DPBrowseSuggestion *> *));
NSURL *DPBrowseDefaultAddress(DPBrowseSource *source, NSString *text);

@interface DPMiniLauncher (SiteSearch)
- (NSString *)prepareSiteSearchQuery;
- (void)enterSiteSearch;
- (void)leaveSiteSearch;
@end
@interface DPMiniLauncher (SiteSearchHeader)
- (void)buildSiteSearch;
- (void)refreshSiteSearchHeader;
@end
