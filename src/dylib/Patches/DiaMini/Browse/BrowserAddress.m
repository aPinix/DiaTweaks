#import "BrowserToolbar.h"
#import "BrowserExtensions.h"

@implementation DPMiniBrowserAddressPill
- (instancetype)initWithOwner:(DPBrowseWindow *)owner {
    if (!(self = [super initWithFrame:NSMakeRect(0,0,300,30)])) return nil;
    self.owner = owner; self.identifier = @"DiaMiniAddressPill"; self.wantsLayer = YES; self.layer.cornerRadius = 6;
    self.editButton = [NSButton buttonWithTitle:@"" target:owner action:@selector(editAddress:)];
    self.editButton.bordered = NO; self.editButton.accessibilityLabel = @"Address — search or enter a URL"; [self addSubview:self.editButton];
    self.searchIcon = [[NSImageView alloc] initWithFrame:NSMakeRect(8,7,16,16)];
    self.searchIcon.image = [NSImage imageWithSystemSymbolName:@"magnifyingglass" accessibilityDescription:nil]; [self addSubview:self.searchIcon];
    self.domain = [NSTextField labelWithString:@"about:blank"]; self.domain.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    self.domain.alignment = NSTextAlignmentCenter; self.domain.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.domain.maximumNumberOfLines = 1; self.domain.cell.wraps = NO;
    self.domain.accessibilityLabel = @"Current domain"; [self addSubview:self.domain];
    self.progressView = [DPMiniBrowserProgress new]; self.progressView.hidden = YES; [self addSubview:self.progressView];
    self.linkButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"link" accessibilityDescription:@"Copy link"] target:owner action:@selector(copyLink:)];
    self.linkButton.bordered = NO; self.linkButton.toolTip = @"Copy link"; self.linkButton.accessibilityLabel = @"Copy link"; [self addSubview:self.linkButton];
    self.extensionButton = DPBrowseMiniExtensionsButton(owner); [self addSubview:self.extensionButton];
    [self updateColors]; return self;
}
- (void)updateColors {
    BOOL dark = [[self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqual:NSAppearanceNameDarkAqua];
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.layer.backgroundColor = [(dark ? NSColor.whiteColor : NSColor.blackColor) colorWithAlphaComponent:dark ? 0.10 : 0.045].CGColor;
        self.layer.borderColor = [(dark ? NSColor.whiteColor : NSColor.blackColor) colorWithAlphaComponent:0.10].CGColor;
        self.layer.borderWidth = 1 / MAX(1, self.window.backingScaleFactor);
    }];
    self.domain.textColor = NSColor.labelColor;
    self.linkButton.contentTintColor = self.extensionButton.contentTintColor = [NSColor.labelColor colorWithAlphaComponent:0.50];
    self.searchIcon.contentTintColor = [NSColor.labelColor colorWithAlphaComponent:0.60];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateColors]; }
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateColors]; }
- (void)viewDidChangeBackingProperties { [super viewDidChangeBackingProperties]; [self updateColors]; }
- (void)layout {
    [super layout]; CGFloat width = NSWidth(self.bounds);
    self.editButton.frame = NSMakeRect(0,0,MAX(1,width-64),30);
    CGFloat height = self.domain.fittingSize.height, textWidth = MAX(1,width-96);
    self.domain.frame = NSMakeRect(30,(30-height)/2,textWidth,height);
    self.extensionButton.frame = NSMakeRect(MAX(0,width-61),3,26,24);
    self.linkButton.frame = NSMakeRect(MAX(0,width-29),3,26,24);
    self.progressView.frame = NSMakeRect(30+textWidth/2-24,3,48,2);
}
- (NSView *)hitTest:(NSPoint)point {
    NSView *hit = [super hitTest:point];
    return hit == self.domain || hit == self.searchIcon || hit == self.progressView ? self.editButton : hit;
}
- (void)showURL:(NSURL *)url loading:(BOOL)loading progress:(double)progress {
    NSString *host = url.host ?: url.absoluteString ?: @"about:blank";
    if ([host.lowercaseString hasPrefix:@"www."]) host = [host substringFromIndex:4];
    self.domain.stringValue = host;
    self.editButton.toolTip = url.absoluteString ?: @"Search or enter a URL";
    self.editButton.accessibilityValue = url.absoluteString ?: @"about:blank";
    self.linkButton.enabled = url != nil;
    self.progressView.hidden = !loading; self.progressView.progress = MAX(0,MIN(1,progress)); self.progressView.needsDisplay = YES;
}
@end
