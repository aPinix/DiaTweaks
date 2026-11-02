#import "BrowserOpenChooserInternal.h"

@interface DPMiniDestinationPanel : NSPanel
@end
@implementation DPMiniDestinationPanel
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return NO; }
@end
@interface DPMiniBrowserDestinationPicker ()
@property(strong, readwrite) DPMiniBrowserDestinations *contentViewController;
@property(strong) NSPanel *panel;
@property(weak) NSView *anchor;
@property(strong) id outsideMonitor, deactivateObserver;
@property(copy) NSArray *parentObservers;
@property BOOL closing;
- (void)closeReturningFocus:(BOOL)returnFocus;
@end

@implementation DPMiniBrowserDestinationPicker
- (instancetype)initWithContentViewController:(DPMiniBrowserDestinations *)controller {
    if ((self = [super init])) self.contentViewController = controller;
    return self;
}
- (BOOL)shown { return self.panel.visible; }
- (void)showRelativeToView:(NSView *)view {
    if (!view.window || self.shown) return;
    NSView *root = self.contentViewController.view; self.anchor = view;
    NSRect anchor = [view.window convertRectToScreen:[view convertRect:view.bounds toView:nil]];
    NSRect visible = (view.window.screen ?: NSScreen.mainScreen).visibleFrame; NSSize size = root.frame.size;
    CGFloat x = NSMaxX(anchor)-size.width, y = NSMaxY(anchor)+2-size.height;
    x = MAX(NSMinX(visible)+4,MIN(x,NSMaxX(visible)-size.width-4));
    y = MAX(NSMinY(visible)+4,MIN(y,NSMaxY(visible)-size.height-4));
    CGFloat scale = MAX(1,view.window.backingScaleFactor);
    NSPanel *panel = [[DPMiniDestinationPanel alloc] initWithContentRect:NSMakeRect(round(x*scale)/scale,round(y*scale)/scale,size.width,size.height)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    panel.releasedWhenClosed = NO; panel.opaque = NO; panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = YES; panel.hidesOnDeactivate = NO; panel.animationBehavior = NSWindowAnimationBehaviorNone;
    panel.appearance = view.window.effectiveAppearance; panel.level = view.window.level+1;
    panel.collectionBehavior = NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary;
    panel.title = self.contentViewController.catalog.title ?: @"Dia destinations";
    panel.identifier = @"DiaTweaks.MiniDestinationPicker"; panel.delegate = self;
    panel.contentViewController = self.contentViewController; self.panel = panel;
    [view.window addChildWindow:panel ordered:NSWindowAbove]; [panel makeKeyAndOrderFront:nil];
    [panel makeFirstResponder:self.contentViewController.search];
    __weak DPMiniBrowserDestinationPicker *weak = self;
    self.outsideMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown handler:^NSEvent *(NSEvent *event) {
        DPMiniBrowserDestinationPicker *picker = weak;
        if (!picker.shown || event.window == picker.panel) return event;
        NSView *anchorView = picker.anchor;
        BOOL toggle = anchorView && event.window == anchorView.window && NSPointInRect([anchorView convertPoint:event.locationInWindow fromView:nil],anchorView.bounds);
        [picker close]; return toggle ? nil : event;
    }];
    self.deactivateObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSApplicationDidResignActiveNotification object:NSApp queue:nil
        usingBlock:^(NSNotification *note) { [weak close]; }];
    NSMutableArray *observers = [NSMutableArray array];
    for (NSNotificationName name in @[NSWindowWillMoveNotification,NSWindowDidResizeNotification,NSWindowWillCloseNotification])
        [observers addObject:[NSNotificationCenter.defaultCenter addObserverForName:name object:view.window queue:nil
            usingBlock:^(NSNotification *note) { [weak closeReturningFocus:NO]; }]];
    self.parentObservers = observers;
}
- (void)windowDidResignKey:(NSNotification *)notification { [self close]; }
- (void)close { [self closeReturningFocus:YES]; }
- (void)closeReturningFocus:(BOOL)returnFocus {
    if (self.closing) return;
    self.closing = YES;
    if (self.outsideMonitor) [NSEvent removeMonitor:self.outsideMonitor]; self.outsideMonitor = nil;
    if (self.deactivateObserver) [NSNotificationCenter.defaultCenter removeObserver:self.deactivateObserver]; self.deactivateObserver = nil;
    for (id observer in self.parentObservers) [NSNotificationCenter.defaultCenter removeObserver:observer]; self.parentObservers = nil;
    NSPanel *panel = self.panel; NSWindow *parent = panel.parentWindow; BOOL key = panel.keyWindow;
    panel.delegate = nil; [parent removeChildWindow:panel]; [panel orderOut:nil]; [panel close]; self.panel = nil;
    if (returnFocus && key && parent.visible && NSApp.active) [parent makeKeyWindow];
    self.closing = NO;
}
- (void)dealloc {
    if (self.outsideMonitor) [NSEvent removeMonitor:self.outsideMonitor];
    if (self.deactivateObserver) [NSNotificationCenter.defaultCenter removeObserver:self.deactivateObserver];
    for (id observer in self.parentObservers) [NSNotificationCenter.defaultCenter removeObserver:observer];
    self.panel.delegate = nil; [self.panel.parentWindow removeChildWindow:self.panel]; [self.panel orderOut:nil];
}
@end
