#import "BrowserToolbar.h"

@implementation DPMiniBrowserProgress
- (void)drawRect:(NSRect)dirty {
    [[NSColor.secondaryLabelColor colorWithAlphaComponent:0.25] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:1 yRadius:1] fill];
    NSRect fill = self.bounds; fill.size.width *= MAX(0.03, MIN(1, self.progress));
    [NSColor.controlAccentColor setFill]; [[NSBezierPath bezierPathWithRoundedRect:fill xRadius:1 yRadius:1] fill];
}
@end
