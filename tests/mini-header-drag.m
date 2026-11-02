#import "Patches/DiaMini/Browse/BrowserToolbar.h"
@interface DPMiniGestureWindow : NSWindow
@property(copy) NSArray<NSEvent *> *events;
@property NSUInteger drags, clicks;
@end
@implementation DPMiniGestureWindow
- (NSEvent *)nextEventMatchingMask:(NSEventMask)mask {
    NSEvent *event = self.events.firstObject;
    if (event) self.events = [self.events subarrayWithRange:NSMakeRange(1,self.events.count-1)];
    return event;
}
- (void)performWindowDragWithEvent:(NSEvent *)event {
    NSCAssert(event.type == NSEventTypeLeftMouseDown,@"native dragging receives the original press"); self.drags++;
}
- (void)click:(id)sender { self.clicks++; }
@end
static NSEvent *DPMiniGesture(NSWindow *window, NSEventType type, CGFloat x, CGFloat y) {
    return [NSEvent mouseEventWithType:type location:NSMakePoint(x,y) modifierFlags:0 timestamp:0
        windowNumber:window.windowNumber context:nil eventNumber:1 clickCount:1 pressure:1];
}
void DPTestMiniHeaderDrag(void) {
    DPMiniGestureWindow *window = [[DPMiniGestureWindow alloc] initWithContentRect:NSMakeRect(0,0,200,100)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO]; window.releasedWhenClosed = NO;
    NSButton *button = DPBrowseHeaderButton(@"",window,@selector(click:)); button.frame = NSMakeRect(0,0,100,30);
    [window.contentView addSubview:button]; NSEvent *down = DPMiniGesture(window,NSEventTypeLeftMouseDown,20,10);
    window.events = @[DPMiniGesture(window,NSEventTypeLeftMouseDragged,22,11),DPMiniGesture(window,NSEventTypeLeftMouseUp,22,11)];
    [button mouseDown:down]; NSCAssert(window.clicks == 1 && !window.drags,@"small pointer movement remains a click");
    window.events = @[DPMiniGesture(window,NSEventTypeLeftMouseDragged,25,10)];
    CGFloat originalX = NSMinX(window.frame);
    [button mouseDown:down]; NSCAssert(window.clicks == 1 && window.drags == 1 && NSMinX(window.frame) == originalX+5,
        @"dragging preserves its initial movement without invoking the button action");
    window.events = @[DPMiniGesture(window,NSEventTypeLeftMouseUp,150,40)];
    [button mouseDown:down]; NSCAssert(window.clicks == 1,@"releasing outside cancels the click"); [window close];
}
