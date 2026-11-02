#import "Peek.h"

@interface DPPeekBadge : NSView
@property (strong) NSImageView *icon;
- (void)layoutForTile:(BOOL)tile;
@end

@interface DPPeekIndicator : NSObject
@property (weak) DPPeekCard *peek;
@property (weak) NSView *row;
@property (weak) NSView *reservedRow;
@property (weak) id<NSAccessibility> element;
@property (strong) DPPeekBadge *badge;
@property (strong) NSView *outline;
@property (strong) NSTimer *timer;
- (void)update;
@end
id<NSAccessibility> DPPeekSelectedTab(id root);
NSRect DPPeekIndicatorFrame(NSRect row, BOOL tile, BOOL flipped);
void DPPeekInstallTabSpacing(void);
void DPPeekReserveTabSpace(NSView *row);
void DPPeekRestoreTabSpace(NSView *row);
