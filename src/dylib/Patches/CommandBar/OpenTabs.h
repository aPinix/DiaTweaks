#import "CommandBar.h"

@interface DPCommandTabSuggestion : DPBrowseSuggestion
@property (weak, readonly) id contents;
@property (weak, readonly) NSWindow *ownerWindow;
@property (readonly) NSInteger sessionIdentifier;
@property (copy, readonly) NSString *actionLabel;
@end

void DPCommandBarInstallTabLookup(void);
NSArray<DPCommandTabSuggestion *> *DPCommandBarMatchingTabs(DPBrowseSource *source, NSString *query);
BOOL DPCommandBarTabIsCurrent(DPCommandTabSuggestion *tab, DPBrowseSource *source);
// YES means Dia accepted a selection request, not that an asynchronous UI transition was observed.
BOOL DPCommandBarActivateTab(DPCommandTabSuggestion *tab, DPBrowseSource *source);

// Internal identity helpers shared by lookup and switching.
DPBrowseSource *DPCommandBarSourceForTab(id contents, DPBrowseSource *scope);
NSInteger DPCommandBarTabSession(id contents);
