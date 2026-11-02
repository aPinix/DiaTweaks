#import "Patches/Peek/Button.h"

// Paths share the circle's exact center. They stay vector-sharp at every display scale.
CGPathRef DPPeekSymbolPath(NSInteger symbol, NSRect bounds) {
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat x = NSMidX(bounds), y = NSMidY(bounds);
    void (^move)(CGFloat, CGFloat) = ^(CGFloat dx, CGFloat dy) { CGPathMoveToPoint(path, NULL, x + dx, y + dy); };
    void (^line)(CGFloat, CGFloat) = ^(CGFloat dx, CGFloat dy) { CGPathAddLineToPoint(path, NULL, x + dx, y + dy); };
    if (symbol == 0) {
        move(-5, -5); line(5, 5); move(-5, 5); line(5, -5);
    } else if (symbol == 1) {
        move(-1.5, -1.5); line(-5.5, -5.5);
        move(-5.5, -1.5); line(-5.5, -5.5); line(-1.5, -5.5);
        move(1.5, 1.5); line(5.5, 5.5);
        move(1.5, 5.5); line(5.5, 5.5); line(5.5, 1.5);
    } else {
        CGPathAddRoundedRect(path, NULL, CGRectMake(x - 6, y - 5.5, 12, 11), 1.5, 1.5);
        move(0, -5.5); line(0, 5.5);
    }
    return path;
}
