#import "Patches/Peek/Indicator.h"

@implementation DPPeekBadge
- (instancetype)initWithFrame:(NSRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.wantsLayer = YES;
    self.layer.shadowRadius = 2;
    self.accessibilityElement = YES;
    self.accessibilityRole = NSAccessibilityImageRole;
    self.accessibilityLabel = @"Peek open";
    self.icon = [NSImageView new];
    self.icon.imageScaling = NSImageScaleProportionallyDown;
    self.icon.accessibilityElement = NO;
    [self addSubview:self.icon];
    return self;
}
- (void)layoutForTile:(BOOL)tile {
    self.icon.frame = tile ? self.bounds : NSInsetRect(self.bounds, 4, 4);
    self.layer.cornerRadius = tile ? 4 : 6;
    self.layer.shadowOpacity = tile ? 0.18 : 0.06;
}
- (void)updateSurface {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.layer.backgroundColor = NSColor.controlBackgroundColor.CGColor;
    }];
}
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateSurface]; }
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateSurface]; }
// A favicon is a decoration; the native row keeps its click and drag targets.
- (NSView *)hitTest:(NSPoint)point { return nil; }
@end
