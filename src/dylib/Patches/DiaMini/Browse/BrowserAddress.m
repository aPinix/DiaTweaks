#import "BrowserToolbar.h"

@implementation DPMiniBrowserAddressPill
- (instancetype)initWithOwner:(DPBrowseWindow *)owner {
    if (!(self = [super initWithFrame:NSMakeRect(0,0,300,30)])) return nil;
    self.owner = owner; self.identifier = @"DiaMiniAddressPill"; self.wantsLayer = YES; self.layer.cornerRadius = 6;
    self.editButton = [NSButton buttonWithTitle:@"" target:owner action:@selector(editAddress:)];
    self.editButton.bordered = NO; self.editButton.accessibilityLabel = @"Address — search or enter a URL"; [self addSubview:self.editButton];
    self.searchIcon = [[NSImageView alloc] initWithFrame:NSMakeRect(8,7,16,16)];
    self.searchIcon.image = [NSImage imageWithSystemSymbolName:@"magnifyingglass" accessibilityDescription:nil]; [self addSubview:self.searchIcon];
    self.domain = [NSTextField labelWithString:@"about:blank"]; self.domain.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
    self.domain.alignment = NSTextAlignmentCenter; self.domain.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.domain.accessibilityLabel = @"Current domain"; [self addSubview:self.domain];
    self.progressView = [DPMiniBrowserProgress new]; self.progressView.hidden = YES; [self addSubview:self.progressView];
    self.linkButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"link" accessibilityDescription:@"Copy link"] target:owner action:@selector(copyLink:)];
    self.linkButton.bordered = NO; self.linkButton.toolTip = @"Copy link"; self.linkButton.accessibilityLabel = @"Copy link"; [self addSubview:self.linkButton];
    [self updateColors]; return self;
}
- (void)updateColors {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.layer.backgroundColor = [NSColor.controlBackgroundColor colorWithAlphaComponent:0.45].CGColor;
        self.layer.borderColor = [NSColor.separatorColor colorWithAlphaComponent:0.35].CGColor; self.layer.borderWidth = 0.5;
    }];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateColors]; }
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateColors]; }
- (void)layout {
    [super layout]; CGFloat width = NSWidth(self.bounds);
    self.editButton.frame = NSMakeRect(0,0,MAX(1,width-30),30);
    self.domain.frame = NSMakeRect(34,10,MAX(1,width-68),16);
    self.linkButton.frame = NSMakeRect(MAX(0,width-30),3,26,24);
    self.progressView.frame = NSMakeRect(width/2-24,5,48,2);
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
