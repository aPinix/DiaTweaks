#import "Patches/Peek/Peek.h"
#import "Patches/Peek/Button.h"

// Top to bottom: close, open as tab, open in split view. Each button's tag is the exit it stands for. Fixed frames
// rather than a stack view, which squeezed the circles out of shape.
NSView *DPPeekControls(id target, SEL action) {
    static const CGFloat side = 40, gap = 3, padding = 3;
    NSArray *titles = @[@"Close Peek", @"Open as Tab", @"Open in Split View"];
    // Hover grows each circle beyond its frame. Keep those pixels inside the host's bounds too.
    NSView *controls = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, side + padding * 2, titles.count * side + (titles.count - 1) * gap + padding * 2)];
    controls.clipsToBounds = NO;
    for (NSUInteger i = 0; i < titles.count; i++) {
        DPPeekButton *button = [DPPeekButton buttonWithTitle:@"" target:target action:action];
        button.tag = i;
        button.bordered = NO;
        button.toolTip = titles[i];
        button.accessibilityLabel = titles[i];
        button.wantsLayer = YES;
        button.clipsToBounds = NO;
        button.frame = NSMakeRect(padding, padding + (titles.count - 1 - i) * (side + gap), side, side);
        [button updateAppearanceAnimated:NO];
        [controls addSubview:button];
    }
    return controls;
}
