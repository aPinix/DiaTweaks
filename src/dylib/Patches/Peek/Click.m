#import "Patches/Peek/Peek.h"

static __weak NSWindow *DPClickWindow;
static NSTimeInterval DPClickTime;
static NSPoint DPClickPoint;

void DPPeekRememberClick(NSWindow *window, NSEventModifierFlags flags, NSPoint locationInWindow) {
    NSEventModifierFlags mask = NSEventModifierFlagShift | NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagControl;
    DPClickWindow = (flags & mask) == NSEventModifierFlagShift ? window : nil;
    DPClickTime = NSProcessInfo.processInfo.systemUptime;
    DPClickPoint = locationInWindow;
}

BOOL DPPeekHasRecentClick(NSWindow *window) {
    return DPClickWindow && DPClickWindow == window && NSProcessInfo.processInfo.systemUptime - DPClickTime < 2;
}

NSPoint DPPeekTakeClickPoint(NSWindow *window) {
    NSPoint point = DPPeekHasRecentClick(window) ? DPClickPoint : [window convertPointFromScreen:NSEvent.mouseLocation];
    DPClickWindow = nil;
    return point;
}
