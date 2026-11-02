#import "QuickBrowse.h"

@implementation DPBrowseWindow (Chrome)
- (NSButton *)button:(NSString *)symbol label:(NSString *)label action:(SEL)action {
    NSButton *button = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:symbol accessibilityDescription:label]
        target:self action:action];
    button.bezelStyle = NSBezelStyleTexturedRounded;
    button.toolTip = label; button.accessibilityLabel = label;
    return button;
}

- (void)buildChrome {
    NSView *root = self.window.contentView;
    self.address = [NSTextField new];
    self.address.placeholderString = @"Search or enter a URL";
    self.address.accessibilityLabel = @"Address";
    self.address.target = self; self.address.action = @selector(navigate:); self.address.delegate = self;
    self.address.font = [NSFont systemFontOfSize:13];
    [self.address setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSButton *open = [NSButton buttonWithTitle:@"Open in Dia" target:self action:@selector(promote:)];
    open.bezelStyle = NSBezelStyleRounded; open.toolTip = @"Keep this page as a Dia tab (⌘Return)";
    self.backButton = [self button:@"chevron.left" label:@"Back" action:@selector(back:)];
    self.forwardButton = [self button:@"chevron.right" label:@"Forward" action:@selector(forward:)];
    self.backButton.enabled = self.forwardButton.enabled = NO;
    NSStackView *bar = [NSStackView stackViewWithViews:@[self.backButton, self.forwardButton,
        [self button:@"arrow.clockwise" label:@"Reload" action:@selector(reload:)], self.address, open]];
    bar.spacing = 6; bar.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    self.host.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:bar]; [root addSubview:self.host];
    [NSLayoutConstraint activateConstraints:@[
        [bar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:10],
        [bar.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-10],
        [bar.topAnchor constraintEqualToAnchor:root.topAnchor constant:8],
        [bar.heightAnchor constraintEqualToConstant:30],
        [self.host.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.host.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.host.topAnchor constraintEqualToAnchor:bar.bottomAnchor constant:8],
        [self.host.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
    ]];
    // The title bar is additional to the content rect; clamp the final outer frame too.
    NSRect screen = (self.window.screen ?: self.source.window.screen ?: NSScreen.mainScreen).visibleFrame;
    NSRect frame = self.window.frame;
    frame.size.height = MIN(frame.size.height, screen.size.height);
    frame.origin.y = MAX(NSMinY(screen), MIN(frame.origin.y, NSMaxY(screen) - frame.size.height));
    [self.window setFrame:frame display:NO];
}

- (void)updatePage {
    if (self.closing) return;
    NSURL *url = self.contents.url;
    self.backButton.enabled = self.contents.canGoBack;
    self.forwardButton.enabled = self.contents.canGoForward;
    if (!self.address.currentEditor && url) self.address.stringValue = url.absoluteString;
    NSString *title = self.contents.title;
    self.window.title = title.length ? [@"Dia Mini — " stringByAppendingString:title] : @"Dia Mini";
}
@end
