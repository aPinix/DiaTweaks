#import "BrowserToolbar.h"

const CGFloat DPMiniBrowserHeaderHeight = 48;

@interface DPMiniHeaderTint : NSView
@end
@implementation DPMiniHeaderTint
- (NSView *)hitTest:(NSPoint)point { return nil; }
@end

@implementation DPMiniBrowserHeader
- (BOOL)isFlipped { return YES; }
- (instancetype)initWithOwner:(DPBrowseWindow *)owner {
    if (!(self = [super initWithFrame:NSMakeRect(0, 0, NSWidth(owner.window.frame), DPMiniBrowserHeaderHeight)])) return nil;
    self.owner = owner; self.identifier = @"DiaMiniBrowserHeader";
    self.material = NSVisualEffectMaterialTitlebar; self.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    self.state = NSVisualEffectStateActive; self.wantsLayer = YES;
    self.tint = [[DPMiniHeaderTint alloc] initWithFrame:self.bounds]; self.tint.wantsLayer = YES;
    self.tint.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; [self addSubview:self.tint];
    [self addSubview:owner.addressPill]; [self addSubview:owner.openControl];
    [self updateTint]; return self;
}
- (void)updateTint {
    BOOL dark = [[self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqual:NSAppearanceNameDarkAqua];
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.tint.layer.backgroundColor = (dark ? [NSColor colorWithSRGBRed:0.03 green:0.025 blue:0.10 alpha:0.32]
            : [NSColor.whiteColor colorWithAlphaComponent:0.30]).CGColor;
    }];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateTint]; }
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateTint]; }
- (void)installWindowButtons {
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSUInteger index = 0; index < 3; index++) {
        [self.window standardWindowButton:(NSWindowButton)index].hidden = YES;
        NSButton *button = [NSWindow standardWindowButton:(NSWindowButton)index forStyleMask:self.window.styleMask];
        button.target = self.window;
        button.action = index == 0 ? @selector(performClose:) : index == 1 ? @selector(performMiniaturize:) : @selector(toggleFullScreen:);
        button.accessibilityLabel = @[@"Close",@"Minimize",@"Full Screen"][index];
        [buttons addObject:button];
        NSSize size = button.frame.size;
        [self addSubview:button];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [button.centerXAnchor constraintEqualToAnchor:self.leadingAnchor constant:18 + index * 23],
            [button.centerYAnchor constraintEqualToAnchor:self.topAnchor constant:24],
            [button.widthAnchor constraintEqualToConstant:size.width], [button.heightAnchor constraintEqualToConstant:size.height]
        ]];
    }
    self.windowButtons = buttons;
    self.needsLayout = YES;
}
- (void)layout {
    [super layout];
    CGFloat width = NSWidth(self.bounds), openWidth = MIN(self.owner.openControl.intrinsicContentSize.width, MAX(26, width - 131));
    self.owner.openControl.frame = NSMakeRect(width - openWidth - 8, 8, openWidth, 30);
    self.owner.addressPill.frame = NSMakeRect(83, 8, MAX(1, width - openWidth - 99), 30);
    for (NSUInteger index = 0; index < 3; index++) {
        NSButton *button = self.windowButtons[index];
        NSSize size = button.frame.size;
        button.frame = NSMakeRect(18 + index * 23 - size.width / 2, 24 - size.height / 2, size.width, size.height);
    }
}
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (void)mouseDown:(NSEvent *)event { [self.window performWindowDragWithEvent:event]; }
@end
