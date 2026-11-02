#import "Shortcut.h"

@implementation DPMiniShortcutRecorder (Events)
- (BOOL)consumeEvent:(NSEvent *)event {
    if (!self.recording) return NO;
    if (event.type == NSEventTypeLeftMouseDown || event.type == NSEventTypeRightMouseDown) {
        if (event.window != self.window || !NSPointInRect([self convertPoint:event.locationInWindow fromView:nil], self.bounds)) [self stopRecording];
        return NO;
    }
    if (event.window != self.window) { [self stopRecording]; return NO; }
    if (event.type == NSEventTypeKeyDown) {
        if (event.isARepeat) return YES;
        if (event.keyCode == kVK_Escape && !(event.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift))) {
            self.message = nil; [self stopRecording]; return YES;
        }
        self.pending = [DPMiniShortcut fromEvent:event];
        self.message = self.pending ? nil : @"Include Command, Control or Option with a key.";
        [self refresh];
        return YES;
    }
    if (event.type == NSEventTypeKeyUp && self.pending && event.keyCode == self.pending.keyCode) {
        // Register after release so recording the shortcut cannot also open Mini.
        NSString *error = nil;
        if (DPMiniSaveShortcut(self.pending, NO, &error)) { self.message = nil; [self stopRecording]; }
        else { self.pending = nil; self.message = error; [self refresh]; }
        return YES;
    }
    return event.type == NSEventTypeKeyUp;
}
@end
