#import "WindowCommand.h"

@interface DPMiniCommandScrim : NSView
@property (weak) DPMiniWindowCommand *palette;
@end
@implementation DPMiniCommandScrim
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (void)mouseDown:(NSEvent *)event { self.palette.restorePrevious = NO; [self.palette close]; }
- (void)rightMouseDown:(NSEvent *)event { [self mouseDown:event]; }
- (void)scrollWheel:(NSEvent *)event {}
@end

@implementation DPMiniWindowCommand (Backdrop)
- (void)installMiniScrim {
    NSView *host = self.miniOwner.host, *root = host.superview;
    if (!root || self.miniScrim) return;
    DPMiniCommandScrim *scrim = [DPMiniCommandScrim new]; scrim.palette = self;
    scrim.identifier = @"DiaMiniCommandScrim"; scrim.accessibilityElement = NO;
    scrim.wantsLayer = YES; scrim.layer.backgroundColor = [NSColor.blackColor colorWithAlphaComponent:0.35].CGColor;
    scrim.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:scrim positioned:NSWindowAbove relativeTo:host];
    [NSLayoutConstraint activateConstraints:@[[scrim.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [scrim.trailingAnchor constraintEqualToAnchor:host.trailingAnchor], [scrim.topAnchor constraintEqualToAnchor:host.topAnchor],
        [scrim.bottomAnchor constraintEqualToAnchor:host.bottomAnchor]]];
    self.miniScrim = scrim;
    __weak DPMiniWindowCommand *weak = self;
    self.outsideMouseMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown
        handler:^NSEvent *(NSEvent *event) {
            DPMiniWindowCommand *palette = weak; DPBrowseWindow *owner = palette.miniOwner;
            if (!palette.window.visible || event.window != owner.window) return event;
            NSPoint point = [owner.host convertPoint:event.locationInWindow fromView:nil];
            if (!NSPointInRect(point, owner.host.bounds)) return event;
            palette.restorePrevious = NO; [palette close]; return nil;
        }];
}
- (void)removeMiniScrim {
    if (self.outsideMouseMonitor) [NSEvent removeMonitor:self.outsideMouseMonitor];
    self.outsideMouseMonitor = nil;
    [self.miniScrim removeFromSuperview]; self.miniScrim = nil;
}
@end
