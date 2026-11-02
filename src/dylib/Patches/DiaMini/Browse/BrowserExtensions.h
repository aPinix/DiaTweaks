#import "QuickBrowse.h"

@interface DPMiniExtensionItem : NSObject
@property(copy) NSString *identifier, *name;
@property(strong) NSImage *icon;
@property BOOL enabled, hasAction;
@property(readonly) NSString *status;
@end

@interface DPMiniExtensionCatalog : NSObject
@property(copy) NSArray<DPMiniExtensionItem *> *items;
@property(copy) NSString *message;
@property BOOL available, ready;
@end
DPMiniExtensionCatalog *DPBrowseMiniExtensionCatalog(DPBrowseWindow *owner);

@interface DPMiniExtensionList : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate, NSPopoverDelegate>
@property(weak) DPBrowseWindow *owner;
@property(strong) DPMiniExtensionCatalog *catalog;
@property(copy) NSArray<DPMiniExtensionItem *> *filtered;
@property(strong) NSSearchField *search;
@property(strong) NSTableView *table;
@property(strong) NSTextField *status;
@property(strong) NSButton *openButton;
@property(strong) id ownerCloseObserver;
- (void)reloadCatalog:(id)sender;
- (void)filter:(id)sender;
- (void)openInDia:(id)sender;
@end
@interface DPMiniExtensionList (Lifecycle)
- (void)stopWatchingOwner;
@end

NSButton *DPBrowseMiniExtensionsButton(DPBrowseWindow *owner);
NSPopover *DPBrowseMiniExtensionsPopover(DPBrowseWindow *owner);
void DPBrowseCloseMiniExtensions(DPBrowseWindow *owner);
@interface DPBrowseWindow (Extensions)
- (void)showMiniExtensions:(id)sender;
@end
