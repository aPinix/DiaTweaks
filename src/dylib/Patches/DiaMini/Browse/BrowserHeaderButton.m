#import "BrowserToolbar.h"

@interface DPMiniHeaderButton : NSButton
@end
@implementation DPMiniHeaderButton
- (void)mouseDown:(NSEvent *)event {
    if (!self.enabled) return;
    NSPoint start = event.locationInWindow;
    [self highlight:YES];
    for (;;) {
        NSEvent *next = [self.window nextEventMatchingMask:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp];
        if (!next) { [self highlight:NO]; return; }
        NSPoint point = next.locationInWindow;
        if (next.type == NSEventTypeLeftMouseDragged && hypot(point.x-start.x,point.y-start.y) >= 4) {
            [self highlight:NO];
            // Preserve the movement consumed while distinguishing a click from a drag.
            NSWindow *window = self.window; NSPoint origin = window.frame.origin;
            [window setFrameOrigin:NSMakePoint(origin.x+point.x-start.x,origin.y+point.y-start.y)];
            [window performWindowDragWithEvent:event]; return;
        }
        if (next.type == NSEventTypeLeftMouseUp) {
            [self highlight:NO];
            if (NSPointInRect([self convertPoint:point fromView:nil],self.bounds)) [self performClick:nil];
            return;
        }
    }
}
@end
NSButton *DPBrowseHeaderButton(NSString *title, id target, SEL action) {
    NSButton *button = [DPMiniHeaderButton new]; button.title = title;
    if (!title.length) button.imagePosition = NSImageOnly;
    button.target = target; button.action = action; return button;
}
