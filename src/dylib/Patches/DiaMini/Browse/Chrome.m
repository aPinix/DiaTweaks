#import "BrowserToolbar.h"

static NSToolbarItemIdentifier const DPAddressItem = @"DiaTweaks.MiniAddress";
static NSToolbarItemIdentifier const DPOpenItem = @"DiaTweaks.MiniOpen";

@implementation DPBrowseWindow (Chrome)
- (void)buildChrome {
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.toolbarStyle = NSWindowToolbarStyleUnifiedCompact;
    self.window.titlebarSeparatorStyle = NSTitlebarSeparatorStyleNone;
    // Keep the full URL as the navigation draft; the visible pill displays only its domain.
    self.address = [NSTextField new]; self.address.hidden = YES;
    self.addressPill = [[DPMiniBrowserAddressPill alloc] initWithOwner:self];
    self.openControl = [[DPMiniBrowserOpenControl alloc] initWithOwner:self];
    self.addressPill.translatesAutoresizingMaskIntoConstraints = self.openControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.addressWidth = [self.addressPill.widthAnchor constraintEqualToConstant:MAX(180, NSWidth(self.window.frame) - 270)];
    self.addressWidth.active = YES;
    [self.addressPill.heightAnchor constraintEqualToConstant:30].active = YES;
    [self.openControl.widthAnchor constraintEqualToConstant:150].active = YES;
    [self.openControl.heightAnchor constraintEqualToConstant:30].active = YES;
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"DiaTweaks.MiniBrowserToolbar"];
    toolbar.delegate = self; toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    toolbar.allowsUserCustomization = NO; toolbar.autosavesConfiguration = NO;
    self.window.toolbar = toolbar;
    NSView *root = self.window.contentView;
    self.host.translatesAutoresizingMaskIntoConstraints = NO; [root addSubview:self.host];
    [NSLayoutConstraint activateConstraints:@[
        [self.host.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.host.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.host.topAnchor constraintEqualToAnchor:root.topAnchor],
        [self.host.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
    ]];
}
@end

@implementation DPBrowseWindow (ToolbarItems)
- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[DPAddressItem, NSToolbarFlexibleSpaceItemIdentifier, DPOpenItem];
}
- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar { return [self toolbarAllowedItemIdentifiers:toolbar]; }
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)identifier willBeInsertedIntoToolbar:(BOOL)inserted {
    if (![identifier isEqual:DPAddressItem] && ![identifier isEqual:DPOpenItem]) return nil;
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    item.bordered = NO;
    item.view = [identifier isEqual:DPAddressItem] ? self.addressPill : self.openControl;
    item.label = [identifier isEqual:DPAddressItem] ? @"Address" : @"Open in Dia";
    item.visibilityPriority = NSToolbarItemVisibilityPriorityHigh;
    return item;
}
@end
