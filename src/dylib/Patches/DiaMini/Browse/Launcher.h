#import "QuickBrowse.h"

enum { DPMiniHeaderHeight = 64, DPMiniListTop = 68, DPMiniRowHeight = 50, DPMiniListBottom = 12, DPMiniResultLimit = 5 };
@class DPSiteSearchProvider;

@interface DPBrowseSuggestion : NSObject
@property (copy) NSString *title;
@property (strong) NSURL *url;
@property (strong) NSImage *icon;
@property BOOL iconRequested;
@property BOOL searchQuery;
@property (getter=isFromKeyword) BOOL fromKeyword;
@property (copy) NSString *keyword;
@property (copy) NSString *inlineAutocompleteText, *fillIntoEdit;
@property BOOL allowedToBeDefaultMatch, hasTabMatch;
@property (copy, readonly) NSString *actionLabel;
@end

@interface DPMiniLauncher : NSWindowController <NSTextFieldDelegate, NSWindowDelegate>
@property (strong) DPBrowseSource *source;
@property (strong) NSTextField *search, *status;
@property (strong) NSWindow *shadowWindow;
@property (strong) NSImageView *searchIcon;
@property (strong) NSButton *closeButton, *sitePrompt, *siteBadge;
@property (strong) DPSiteSearchProvider *siteProvider, *siteCandidate;
@property (copy) NSString *siteCompletion, *siteExitText;
@property (copy) NSString *typedQuery, *inputPreview;
@property BOOL rowPreviewing, inputWasDeleted, updatingInput;
@property (strong) NSTableView *table;
@property (strong) NSScrollView *scroll;
@property (copy) NSArray<DPBrowseSuggestion *> *suggestions;
@property (strong) NSRunningApplication *previousApplication;
@property NSUInteger generation;
@property BOOL startingSource;
@property BOOL openingResult;
@property BOOL restorePrevious;
@property BOOL presenting;
@property BOOL commandBar, suppressInlineCompletion;
@property (strong) id activationObserver;
@property (strong) NSTimer *sourceTimer;
- (void)query;
- (void)choose:(id)sender;
- (BOOL)launcherEnabled;
- (void)openURL:(NSURL *)url completion:(void (^)(BOOL opened))completion;
@end
@interface DPMiniLauncher (Presentation)
- (void)show;
@end
@interface DPMiniLauncher (Activation)
- (void)focus;
@end
@interface DPMiniLauncher (UI)
- (void)buildLauncher;
@end
@interface DPMiniLauncher (ResultsData) <NSTableViewDelegate, NSTableViewDataSource>
- (void)setResults:(NSArray<DPBrowseSuggestion *> *)results;
@end
@interface DPMiniLauncher (Results)
- (NSRect)launcherFrameForHeight:(CGFloat)height;
- (void)resizeForResults;
@end
@interface DPMiniLauncher (Shadow)
- (void)updateLauncherShadow;
- (void)closeLauncherShadow;
@end
@interface DPMiniLauncher (InputState)
- (NSString *)prepareInputQuery;
- (void)userInputDidChange;
- (BOOL)shouldPreventInlineCompletion;
- (BOOL)displayInputPreview:(NSString *)value selectedRange:(NSRange)range;
- (void)cancelSiteSearch;
@end
@interface DPMiniLauncher (InputCompletion)
- (void)updateInputForResults;
@end
@interface DPMiniLauncher (InputPreview)
- (void)previewSelectedInput;
- (void)refreshInputIcon;
@end

extern DPMiniLauncher *DPCurrentMiniLauncher;
void DPBrowseShowLauncher(void);
void DPBrowseCloseLauncher(void);
void DPBrowseUpdateHotkey(void);
void DPBrowseStopHotkey(void);
BOOL DPBrowseHotkeyRegistered(void);
id DPBrowseContext(DPBrowseSource *source);
id DPBrowseAutocompleteOwner(DPBrowseSource *source);
NSArray<DPBrowseSuggestion *> *DPBrowseRecents(DPBrowseSource *source);
void DPBrowseRemember(DPBrowseSource *source, NSURL *url, NSString *title);
void DPBrowseRememberQuery(DPBrowseSource *source, NSURL *url, NSString *query, NSString *keyword);
void DPBrowseSuggestions(DPBrowseSource *source, NSString *text, void (^completion)(NSArray<DPBrowseSuggestion *> *));
void DPBrowseInputSuggestions(DPBrowseSource *source, NSString *text, BOOL preventInlineCompletion,
    void (^completion)(NSArray<DPBrowseSuggestion *> *));
NSArray<DPBrowseSuggestion *> *DPBrowseMatches(id result);
BOOL DPBrowseHasPendingLinks(void);
