#import "Patches/DiaMini/Browse/BrowserToolbar.h"

// This command-line fixture has no activated app scene. Model only the app's key-window lookup.
static __weak NSWindow *DPMiniSelectedWindow;
static BOOL DPMiniTestingSelection;
static NSWindow *DPMiniFixtureKeyWindow(NSApplication *self, SEL _cmd) {
    return DPMiniTestingSelection ? DPMiniSelectedWindow : DPCallOriginal(DPMiniFixtureKeyWindow,self);
}
@interface DPMiniDestinationFocusView : NSView
@end
@implementation DPMiniDestinationFocusView
- (BOOL)acceptsFirstResponder { return YES; }
@end

void DPTestMiniDestinationSelection(DPBrowseSource *source) {
    DPHookClass(NSApp.class,@selector(keyWindow),(IMP)DPMiniFixtureKeyWindow);
    DPMiniTestingSelection = YES;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,400,260)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    NSWindow *other = [[NSWindow alloc] initWithContentRect:NSMakeRect(600,100,300,200)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = other.releasedWhenClosed = NO;
    id<DPBrowseContents> page = [objc_getClass(DPDiaWebContents) new];
    DPMiniDestinationFocusView *view = [[DPMiniDestinationFocusView alloc] initWithFrame:NSMakeRect(10,10,300,200)];
    [(id)page setValue:view forKey:@"nativeView"]; [window.contentView addSubview:view];
    DPMiniDestinationFocusView *child = [[DPMiniDestinationFocusView alloc] initWithFrame:NSMakeRect(10,10,100,80)];
    DPMiniDestinationFocusView *outside = [[DPMiniDestinationFocusView alloc] initWithFrame:NSMakeRect(320,10,60,80)];
    [window.contentView addSubview:outside];
    [view addSubview:child]; [window makeKeyAndOrderFront:nil]; [window makeFirstResponder:view]; page.hasFocus = YES;
    DPMiniSelectedWindow = window;
    NSCAssert(DPBrowseAdoptedPageSelected(page,window), @"the exact visible adopted page owns native move actions");
    NSCAssert(!DPBrowseAdoptedPageSelected(page,other), @"another browser window cannot receive an adopted page's action");
    page.hasFocus = NO;
    NSCAssert(!DPBrowseAdoptedPageSelected(page,window), @"another selected tab cannot inherit an unfocused page's native move");
    page.hasFocus = YES; view.hidden = YES;
    NSCAssert(!DPBrowseAdoptedPageSelected(page,window), @"a hidden adopted page cannot dispatch native move actions");
    view.hidden = NO; [window makeFirstResponder:outside];
    NSCAssert(!DPBrowseAdoptedPageSelected(page,window), @"focus outside the adopted page invalidates its native action");
    [window makeFirstResponder:child];
    NSCAssert(DPBrowseAdoptedPageSelected(page,window), @"a native responder inside the live page preserves ownership");
    [other makeKeyAndOrderFront:nil];
    DPMiniSelectedWindow = other;
    NSCAssert(!DPBrowseAdoptedPageSelected(page,window), @"switching key windows cancels native action targeting");
    [window makeKeyAndOrderFront:nil]; [window makeFirstResponder:child];
    DPMiniSelectedWindow = window;
    view.frame = NSMakeRect(500,500,300,200);
    NSCAssert(!DPBrowseAdoptedPageSelected(page,window), @"a page clipped entirely outside its window cannot receive a move");
    view.frame = NSMakeRect(10,10,300,200); [window orderOut:nil];
    NSCAssert(!DPBrowseAdoptedPageSelected(page,window), @"a hidden browser cannot receive an adopted page action");
    DPMiniTestingSelection = NO; DPMiniSelectedWindow = nil;
    [page close]; [window close]; [other close]; [source.window makeKeyAndOrderFront:nil];
}
