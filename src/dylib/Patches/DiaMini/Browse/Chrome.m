#import "BrowserToolbar.h"

@implementation DPBrowseWindow (Chrome)
- (void)buildChrome {
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.titlebarAppearsTransparent = YES;
    self.window.titlebarSeparatorStyle = NSTitlebarSeparatorStyleNone;
    self.window.backgroundColor = NSColor.clearColor; self.window.opaque = NO;
    // Keep the complete URL in the model; all editing uses the single-line palette.
    self.address = [NSTextField new]; self.address.hidden = YES;
    self.addressPill = [[DPMiniBrowserAddressPill alloc] initWithOwner:self];
    self.openControl = [[DPMiniBrowserOpenControl alloc] initWithOwner:self];
    self.browserHeader = [[DPMiniBrowserHeader alloc] initWithOwner:self];
    NSView *root = self.window.contentView;
    root.wantsLayer = YES; root.layer.cornerRadius = 18; root.layer.masksToBounds = YES;
    self.host.translatesAutoresizingMaskIntoConstraints = self.browserHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.host]; [root addSubview:self.browserHeader];
    [NSLayoutConstraint activateConstraints:@[
        [self.host.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.host.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.host.topAnchor constraintEqualToAnchor:root.topAnchor constant:DPMiniBrowserHeaderHeight],
        [self.host.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [self.browserHeader.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.browserHeader.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.browserHeader.topAnchor constraintEqualToAnchor:root.topAnchor],
        [self.browserHeader.heightAnchor constraintEqualToConstant:DPMiniBrowserHeaderHeight],
    ]];
    [(DPMiniBrowserHeader *)self.browserHeader installWindowButtons];
}
@end
