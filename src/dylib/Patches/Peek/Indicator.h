#import "Peek.h"

@interface DPPeekIndicator : NSObject
@property (weak) DPPeekCard *peek;
@property (weak) NSView *row;
@property (weak) id<NSAccessibility> element;
@property (strong) NSImageView *badge;
@property (strong) NSView *outline;
@property (strong) NSTimer *timer;
- (void)update;
@end
id<NSAccessibility> DPPeekSelectedTab(id root);
NSRect DPPeekIndicatorFrame(NSRect row, BOOL tile, BOOL flipped);
