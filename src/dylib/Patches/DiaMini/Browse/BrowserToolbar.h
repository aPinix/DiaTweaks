#import "Launcher.h"
#import "BrowserDestinations.h"

@interface DPMiniBrowserProgress : NSView
@property double progress;
@end
@interface DPMiniBrowserAddressPill : NSView
@property (weak) DPBrowseWindow *owner;
@property (strong) NSTextField *domain;
@property (strong) NSButton *editButton, *linkButton, *extensionButton;
@property (strong) NSImageView *searchIcon;
@property (strong) DPMiniBrowserProgress *progressView;
- (instancetype)initWithOwner:(DPBrowseWindow *)owner;
- (void)showURL:(NSURL *)url loading:(BOOL)loading progress:(double)progress;
@end
@interface DPMiniBrowserOpenControl : NSView
@property (weak) DPBrowseWindow *owner;
@property (strong) NSButton *primary, *arrow;
@property (strong) NSTextField *titleLabel, *shortcutLabel;
- (instancetype)initWithOwner:(DPBrowseWindow *)owner;
- (void)setDestinationTitle:(NSString *)title;
@end

extern const CGFloat DPMiniBrowserHeaderHeight;
NSRect DPBrowseRestoreMiniSize(NSRect frame, NSRect screen);
void DPBrowseSaveMiniSize(NSWindow *window);
@interface DPMiniBrowserHeader : NSVisualEffectView
@property(weak) DPBrowseWindow *owner;
@property(strong) NSView *tint;
@property(copy) NSArray<NSButton *> *windowButtons;
- (instancetype)initWithOwner:(DPBrowseWindow *)owner;
- (void)installWindowButtons;
@end

@interface DPBrowseWindow (AddressActions)
- (void)editAddress:(id)sender;
- (void)copyLink:(id)sender;
- (NSString *)browserURLString;
@end
@interface DPBrowseWindow (OpenDestinations)
- (void)captureNativeDestinations;
- (DPMiniNativeDestinations *)nativeDestinations;
- (void)showOpenDestinations:(id)sender;
@end
@interface DPBrowseWindow (NativeDestinationTransfer)
- (void)openNativeDestination:(DPMiniNativeDestination *)choice;
@end
BOOL DPBrowseMiniPageAdopted(DPBrowseWindow *owner);
BOOL DPBrowseAdoptedPageSelected(id<DPBrowseContents> page, NSWindow *window);

@interface DPMiniBrowserDestinations : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
@property(weak) DPBrowseWindow *owner;
@property(strong) DPMiniNativeDestinations *catalog;
@property(copy) NSArray<DPMiniNativeDestination *> *filtered;
@property(strong) NSTextField *search, *status;
@property(strong) NSTableView *table;
- (void)filter:(id)sender;
- (void)choose:(id)sender;
- (void)dismiss:(id)sender;
@end

@interface DPMiniBrowserDestinationPicker : NSObject <NSWindowDelegate>
@property(readonly) BOOL shown;
@property(strong, readonly) DPMiniBrowserDestinations *contentViewController;
- (instancetype)initWithContentViewController:(DPMiniBrowserDestinations *)controller;
- (void)showRelativeToView:(NSView *)view;
- (void)close;
@end
