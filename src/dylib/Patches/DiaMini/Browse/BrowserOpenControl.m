#import "BrowserToolbar.h"

@implementation DPMiniBrowserOpenControl
- (instancetype)initWithOwner:(DPBrowseWindow *)owner {
    if (!(self = [super initWithFrame:NSMakeRect(0,0,150,30)])) return nil;
    self.owner = owner; self.identifier = @"DiaMiniOpenControl"; self.wantsLayer = YES; self.layer.cornerRadius = 6;
    self.primary = [NSButton buttonWithTitle:@"" target:owner action:@selector(promote:)]; self.primary.bordered = NO;
    self.primary.toolTip = @"Keep this page as a Dia tab (⌘O)"; [self addSubview:self.primary];
    self.titleLabel = [NSTextField labelWithString:@""]; self.titleLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail; self.titleLabel.maximumNumberOfLines = 1;
    self.shortcutLabel = [NSTextField labelWithString:@"⌘O"]; self.shortcutLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
    self.shortcutLabel.alignment = NSTextAlignmentCenter; self.shortcutLabel.textColor = NSColor.secondaryLabelColor;
    self.shortcutLabel.wantsLayer = YES; self.shortcutLabel.layer.cornerRadius = 3;
    self.titleLabel.accessibilityElement = self.shortcutLabel.accessibilityElement = NO;
    [self addSubview:self.titleLabel]; [self addSubview:self.shortcutLabel]; [self setDestinationTitle:@"Dia"];
    self.arrow = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.down" accessibilityDescription:@"Choose Dia destination"] target:owner action:@selector(showOpenDestinations:)];
    self.arrow.bordered = NO; self.arrow.accessibilityLabel = @"Choose Dia destination"; [self addSubview:self.arrow];
    [self updateColors]; return self;
}
- (void)updateColors {
    BOOL dark = [[self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqual:NSAppearanceNameDarkAqua];
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.layer.backgroundColor = (dark ? [NSColor colorWithSRGBRed:0.03 green:0.025 blue:0.12 alpha:0.86]
            : [NSColor.whiteColor colorWithAlphaComponent:0.50]).CGColor;
        self.layer.borderColor = [NSColor.labelColor colorWithAlphaComponent:0.10].CGColor;
        self.layer.borderWidth = 1 / MAX(1,self.window.backingScaleFactor);
        self.shortcutLabel.layer.backgroundColor = [NSColor.labelColor colorWithAlphaComponent:0.10].CGColor;
    }];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateColors]; }
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateColors]; }
- (void)viewDidChangeBackingProperties { [super viewDidChangeBackingProperties]; [self updateColors]; }
- (void)layout {
    [super layout]; self.primary.frame = NSMakeRect(0,0,NSWidth(self.bounds)-26,30);
    self.arrow.frame = NSMakeRect(NSWidth(self.bounds)-26,0,26,30);
    CGFloat height = self.titleLabel.fittingSize.height;
    self.titleLabel.frame = NSMakeRect(10,(30-height)/2,MAX(0,NSWidth(self.bounds)-74),height);
    self.shortcutLabel.frame = NSMakeRect(NSWidth(self.bounds)-58,7,24,16);
}
- (void)setDestinationTitle:(NSString *)title {
    NSString *label = [@"Open in " stringByAppendingString:title.length ? title : @"Dia"];
    if ([self.titleLabel.stringValue isEqual:label]) return;
    self.titleLabel.stringValue = label; self.primary.accessibilityLabel = label;
    [self invalidateIntrinsicContentSize]; self.needsLayout = YES; self.superview.needsLayout = YES;
}
- (NSSize)intrinsicContentSize { return NSMakeSize(MAX(150,ceil(self.titleLabel.fittingSize.width)+78),30); }
- (NSView *)hitTest:(NSPoint)point {
    NSView *hit = [super hitTest:point];
    return hit == self.titleLabel || hit == self.shortcutLabel ? self.primary : hit;
}
- (void)drawRect:(NSRect)dirty {
    [NSColor.separatorColor setFill]; NSRectFill(NSMakeRect(NSWidth(self.bounds)-26,6,0.5,18));
}
@end
