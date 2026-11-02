#import "QuickBrowse.h"
#import "BrowserToolbar.h"
#import <objc/message.h>

@implementation DPBrowseWindow

- (BOOL)startWithURL:(NSURL *)url source:(DPBrowseSource *)source {
    self.source = source;
    self.profileContext = DPBrowseContext(source);
    NSScreen *screen = source.window.screen ?: NSScreen.mainScreen;
    NSRect anchor = NSIsEmptyRect(self.launcherFrame) ? source.window.frame : self.launcherFrame;
    if (!NSIsEmptyRect(self.launcherFrame)) for (NSScreen *candidate in NSScreen.screens)
        if (NSIntersectsRect(candidate.frame, self.launcherFrame)) { screen = candidate; break; }
    NSRect frame = DPBrowseFrame(anchor, screen.visibleFrame);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable;
    NSRect content = [NSWindow contentRectForFrameRect:frame styleMask:style];
    NSWindow *panel = [[NSWindow alloc] initWithContentRect:content styleMask:style backing:NSBackingStoreBuffered defer:NO];
    panel.releasedWhenClosed = NO; panel.tabbingMode = NSWindowTabbingModeDisallowed;
    panel.contentMinSize = NSMakeSize(MIN(440, NSWidth(frame)), MIN(220, MAX(1, NSHeight(frame) - 60)));
    panel.appearance = source.window.effectiveAppearance ?: NSApp.effectiveAppearance;
    panel.title = @"Dia Mini";
    panel.identifier = @"DiaTweaks.DiaMini";
    panel.delegate = self;
    self.window = panel;
    id config = [objc_getClass(DPDiaWebContentsConfiguration) new];
    void (*flag)(id, SEL, BOOL) = (void *)objc_msgSend;
    flag(config, @selector(setForeground:), YES);
    flag(config, @selector(setUntracked:), YES);
    id (*create)(id, SEL, id) = (void *)objc_msgSend;
    self.contents = create(source.browser, @selector(createWebContents:), config);
    if (!self.contents) return NO;
    self.contentsDelegate = [objc_getClass(DPDiaTablessDelegate) new];
    [self.contents setUIDelegate:self.contentsDelegate];
    self.host = [self.contents createPaneHostView];
    if (!self.host) { [self.contents close]; self.contents = nil; return NO; }
    [self buildChrome];
    [panel setFrame:frame display:NO];
    if (url) [self prepareNavigationToURL:url];
    [self.contents attachToPaneHostView:self.host];
    [panel makeKeyAndOrderFront:nil];
    if (url) [panel makeFirstResponder:self.contents.nativeView];
    self.contents.visibility = 0; // ArcWebContentsVisibility: visible.
    self.contents.hasFocus = YES;
    if (url) {
        id (*load)(id, SEL, id, id) = (void *)objc_msgSend;
        load(self.contents.navigationController, @selector(load:initiatorOrigin:), url, nil);
    } else [panel makeFirstResponder:self.host];
    [self updatePage];
    __weak DPBrowseWindow *weakSelf = self;
    self.refresh = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *_) { [weakSelf updatePage]; }];
    return YES;
}

- (void)windowDidBecomeKey:(NSNotification *)note { self.contents.hasFocus = YES; }
- (void)windowDidResignKey:(NSNotification *)note { self.contents.hasFocus = NO; }
- (void)windowWillClose:(NSNotification *)note {
    if (self.closing) return;
    self.closing = YES;
    if (self.promoting && DPBrowseMiniPageAdopted(self)) self.transferred = YES;
    [self.destinationPopover close]; self.destinationPopover = nil;
    BOOL restore = !self.transferred && self.window.isKeyWindow;
    [self.refresh invalidate]; self.refresh = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self.window.parentWindow removeChildWindow:self.window];
    if (!self.transferred) {
        self.contents.hasFocus = NO;
        [self.contents detachFromPaneHostView:self.host];
        [self.contents close];
    }
    self.contents = nil; self.contentsDelegate = nil; self.profileContext = nil;
    [DPBrowseWindows removeObject:self];
    DPBrowseReleaseSource();
    if (restore && self.returnApplication.processIdentifier != NSRunningApplication.currentApplication.processIdentifier)
        [self.returnApplication activateWithOptions:0];
}
- (void)dealloc { [self.refresh invalidate]; [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end
