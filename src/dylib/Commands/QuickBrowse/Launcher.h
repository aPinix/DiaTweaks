#import "QuickBrowse.h"

@interface DPBrowseSuggestion : NSObject
@property (copy) NSString *title;
@property (strong) NSURL *url;
@property (strong) NSImage *icon;
@property BOOL iconRequested;
@end

@interface DPMiniLauncher : NSWindowController <NSTextFieldDelegate, NSWindowDelegate>
@property (strong) DPBrowseSource *source;
@property (strong) NSTextField *search, *hint;
@property (strong) NSTableView *table;
@property (strong) NSScrollView *scroll;
@property (copy) NSArray<DPBrowseSuggestion *> *suggestions;
@property (strong) NSRunningApplication *previousApplication;
@property NSUInteger generation;
@property BOOL startingSource;
@property BOOL openingResult;
@property BOOL restorePrevious;
@property BOOL presenting;
@property (strong) id activationObserver;
@property (strong) NSTimer *sourceTimer;
- (void)show;
- (void)query;
- (void)choose:(id)sender;
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
- (void)resizeForResults;
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
void DPBrowseSuggestions(DPBrowseSource *source, NSString *text, void (^completion)(NSArray<DPBrowseSuggestion *> *));
NSArray<DPBrowseSuggestion *> *DPBrowseMatches(id result);
BOOL DPBrowseHasPendingLinks(void);
