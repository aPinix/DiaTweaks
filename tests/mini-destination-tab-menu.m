#import "Patches/DiaMini/Browse/BrowserDestinations.h"
#import "StdPatch/StdPatch.h"

static NSUInteger DPContextRequests;
static NSMenu *DPSelectedTabContext(id row, SEL selector, NSEvent *event) {
    NSView *view = row;
    NSCAssert(event.type == NSEventTypeRightMouseDown && event.window == view.window
        && NSPointInRect(event.locationInWindow, [view convertRect:view.bounds toView:nil]), @"the native builder receives only a local context description");
    DPContextRequests++; return view.menu;
}
static void DPNoDispatchedMouse(id row, SEL selector, NSEvent *event) {
    NSCAssert(NO, @"building a tab menu must not dispatch a right click");
}
void DPTestMiniDestinationTabMenu(void) {
    Class base = objc_getClass(DPDiaTabView);
    NSCAssert(base, @"native tab stand-in is registered");
    Class rowClass = objc_allocateClassPair(base, "DPMiniDestinationTabFixture", 0);
    class_addMethod(rowClass, @selector(menuForEvent:), (IMP)DPSelectedTabContext, "@@:@");
    class_addMethod(rowClass, @selector(rightMouseDown:), (IMP)DPNoDispatchedMouse, "v@:@"); objc_registerClassPair(rowClass);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,400,250)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = NO;
    NSView *row = [[rowClass alloc] initWithFrame:NSMakeRect(10,100,200,34)];
    [(NSObject *)row setValue:@YES forKey:@"selected"]; row.menu = [NSMenu new];
    [window.contentView addSubview:row]; [window makeKeyAndOrderFront:nil]; DPContextRequests = 0;
    NSCAssert(!DPBrowseMenuForSelectedNativeTab(window, ^BOOL{ return NO; }) && !DPContextRequests,
        @"a different selected page cannot request a tab's contextual actions");
    NSCAssert(DPBrowseMenuForSelectedNativeTab(window, ^BOOL{ return YES; }) == row.menu && DPContextRequests == 1,
        @"the confirmed selected row builds its native context menu without mouse dispatch");
    __block NSUInteger checks = 0;
    NSCAssert(!DPBrowseMenuForSelectedNativeTab(window, ^BOOL{ return ++checks < 3; }),
        @"a selection change inside the native builder invalidates the menu");
    NSView *other = [[rowClass alloc] initWithFrame:NSMakeRect(10,140,200,34)];
    [(NSObject *)other setValue:@YES forKey:@"selected"]; [window.contentView addSubview:other];
    NSCAssert(!DPBrowseMenuForSelectedNativeTab(window, ^BOOL{ return YES; }), @"ambiguous selected rows cannot supply another tab's menu");
    [window close];
}
