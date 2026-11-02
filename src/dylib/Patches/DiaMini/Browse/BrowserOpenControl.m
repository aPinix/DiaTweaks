#import "BrowserToolbar.h"

@implementation DPMiniBrowserOpenControl
- (instancetype)initWithOwner:(DPBrowseWindow *)owner {
    if (!(self = [super initWithFrame:NSMakeRect(0,0,150,30)])) return nil;
    self.owner = owner; self.identifier = @"DiaMiniOpenControl"; self.wantsLayer = YES; self.layer.cornerRadius = 6;
    self.primary = [NSButton buttonWithTitle:@"" target:owner action:@selector(promote:)]; self.primary.bordered = NO;
    NSDictionary *title = @{NSFontAttributeName:[NSFont systemFontOfSize:12 weight:NSFontWeightSemibold], NSForegroundColorAttributeName:NSColor.labelColor};
    NSMutableAttributedString *label = [[NSMutableAttributedString alloc] initWithString:@"Open in Dia  " attributes:title];
    [label appendAttributedString:[[NSAttributedString alloc] initWithString:@"⌘O" attributes:@{
        NSFontAttributeName:[NSFont systemFontOfSize:11 weight:NSFontWeightMedium], NSForegroundColorAttributeName:NSColor.secondaryLabelColor}]];
    self.primary.attributedTitle = label; self.primary.accessibilityLabel = @"Open in Dia";
    self.primary.toolTip = @"Keep this page as a Dia tab (⌘O)"; [self addSubview:self.primary];
    self.arrow = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.down" accessibilityDescription:@"Choose Dia window"] target:owner action:@selector(showOpenDestinations:)];
    self.arrow.bordered = NO; self.arrow.accessibilityLabel = @"Choose Dia window"; [self addSubview:self.arrow];
    [self updateColors]; return self;
}
- (void)updateColors {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.layer.backgroundColor = [NSColor.controlBackgroundColor colorWithAlphaComponent:0.85].CGColor;
        self.layer.borderColor = NSColor.separatorColor.CGColor; self.layer.borderWidth = 0.5;
    }];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateColors]; }
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateColors]; }
- (void)layout {
    [super layout]; self.primary.frame = NSMakeRect(0,0,NSWidth(self.bounds)-26,30);
    self.arrow.frame = NSMakeRect(NSWidth(self.bounds)-26,0,26,30);
}
- (void)drawRect:(NSRect)dirty {
    [NSColor.separatorColor setFill]; NSRectFill(NSMakeRect(NSWidth(self.bounds)-26,6,0.5,18));
}
@end
