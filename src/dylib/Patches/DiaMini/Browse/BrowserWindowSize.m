#import "BrowserToolbar.h"
#import "../Shortcuts/Shortcut.h"

NSRect DPBrowseRestoreMiniSize(NSRect frame, NSRect screen) {
    NSArray *saved = [DPMiniShortcutDefaults() arrayForKey:@"diaMiniWindowSize"];
    if (saved.count != 2 || ![saved[0] isKindOfClass:NSNumber.class] || ![saved[1] isKindOfClass:NSNumber.class]) return frame;
    double width = [saved[0] doubleValue], height = [saved[1] doubleValue];
    if (!isfinite(width) || !isfinite(height) || width < 440 || height < 240) return frame;
    NSPoint center = NSMakePoint(NSMidX(frame),NSMidY(frame));
    frame.size = NSMakeSize(MIN(width,NSWidth(screen)-24),MIN(height,NSHeight(screen)-24));
    frame.origin = NSMakePoint(MAX(NSMinX(screen)+12,MIN(center.x-frame.size.width/2,NSMaxX(screen)-12-frame.size.width)),
        MAX(NSMinY(screen)+12,MIN(center.y-frame.size.height/2,NSMaxY(screen)-12-frame.size.height)));
    return frame;
}
void DPBrowseSaveMiniSize(NSWindow *window) {
    if (!window.visible || window.miniaturized || (window.styleMask & NSWindowStyleMaskFullScreen)) return;
    NSSize size = window.frame.size;
    if (size.width >= 440 && size.height >= 240)
        [DPMiniShortcutDefaults() setObject:@[@(size.width),@(size.height)] forKey:@"diaMiniWindowSize"];
}
