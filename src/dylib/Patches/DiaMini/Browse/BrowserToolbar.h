#import "Launcher.h"

@interface DPMiniBrowserProgress : NSView
@property double progress;
@end
@interface DPMiniBrowserAddressPill : NSView
@property (weak) DPBrowseWindow *owner;
@property (strong) NSTextField *domain;
@property (strong) NSButton *editButton, *linkButton;
@property (strong) NSImageView *searchIcon;
@property (strong) DPMiniBrowserProgress *progressView;
- (instancetype)initWithOwner:(DPBrowseWindow *)owner;
- (void)showURL:(NSURL *)url loading:(BOOL)loading progress:(double)progress;
@end
@interface DPMiniBrowserOpenControl : NSView
@property (weak) DPBrowseWindow *owner;
@property (strong) NSButton *primary, *arrow;
- (instancetype)initWithOwner:(DPBrowseWindow *)owner;
@end

@interface DPBrowseWindow (ToolbarItems) <NSToolbarDelegate>
@end
@interface DPBrowseWindow (AddressActions)
- (void)editAddress:(id)sender;
- (void)copyLink:(id)sender;
- (NSString *)browserURLString;
@end
@interface DPBrowseWindow (OpenDestinations)
- (NSArray<DPBrowseSource *> *)destinationSources;
- (void)showOpenDestinations:(id)sender;
@end
BOOL DPBrowseMiniPageAdopted(DPBrowseWindow *owner);
NSArray<DPBrowseSource *> *DPBrowseMiniSourcesForProfile(DPBrowseWindow *owner, NSArray<DPBrowseSource *> *sources);

@interface DPMiniBrowserDestinations : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate>
@property(weak) DPBrowseWindow *owner;
@property(strong) NSArray<DPBrowseSource *> *sources, *filtered;
@property(strong) NSSearchField *search;
@property(strong) NSTableView *table;
- (void)filter:(id)sender;
- (void)choose:(id)sender;
@end
