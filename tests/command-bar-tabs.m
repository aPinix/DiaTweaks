#import "Patches/CommandBar/CommandBar.h"

@interface DPCommandTestNavigation : NSObject
@property (strong) NSURL *loaded;
@end
@implementation DPCommandTestNavigation
- (id)load:(NSURL *)url initiatorOrigin:(id)origin { self.loaded = url; return nil; }
@end
@interface DPCommandTestPage : NSObject <DPBrowseContents>
@property (strong) NSView *nativeView;
@property (strong) NSURL *url;
@property (strong) NSString *title;
@property (strong) DPCommandTestNavigation *navigationController;
@property (weak) id UIDelegate;
@property BOOL hasFocus, canGoBack, canGoForward, closed;
@property NSInteger visibility;
@end
@implementation DPCommandTestPage
- (instancetype)init { if ((self = [super init])) { _nativeView = [NSView new]; _navigationController = [DPCommandTestNavigation new]; } return self; }
- (NSView *)createPaneHostView { return [NSView new]; }
- (void)attachToPaneHostView:(NSView *)host { [host addSubview:self.nativeView]; }
- (void)detachFromPaneHostView:(NSView *)host { [self.nativeView removeFromSuperview]; }
- (void)close { self.closed = YES; [self.nativeView removeFromSuperview]; }
@end
@interface DPCommandTestBrowser : NSObject
@property (strong) DPCommandTestPage *lastPage;
@property BOOL foreground, untracked;
@end
@implementation DPCommandTestBrowser
- (id)createWebContents:(id)configuration {
    self.foreground = [[configuration valueForKey:@"foreground"] boolValue]; self.untracked = [[configuration valueForKey:@"untracked"] boolValue];
    return self.lastPage = [DPCommandTestPage new];
}
@end
@interface DPCommandTestDelegate : NSObject
@property (weak) NSWindow *window, *palette;
@property BOOL accepts, guarded, hidesPalette;
@end
@implementation DPCommandTestDelegate
- (void)adopt:(DPCommandTestPage *)page {
    self.guarded = DPCommandBarIsAdopting();
    if (!self.accepts) return;
    [self.window.contentView addSubview:page.nativeView];
    if (self.hidesPalette) [self.palette orderOut:nil];
}
- (void)browser:(id)browser didCreateNewWebContents:(DPCommandTestPage *)page isActive:(BOOL)active { NSCAssert(active, @"foreground tab"); [self adopt:page]; }
- (void)webContents:(id)source didCreateNewWebContent:(DPCommandTestPage *)page targetURL:(NSURL *)url disposition:(NSInteger)disposition {
    NSCAssert(disposition == DPBrowseForegroundTab, @"normal tab disposition"); [self adopt:page];
}
@end

void DPTestCommandBarTabs(void) {
    BOOL enabled = DPCommandBar.on; DPCommandBar.on = YES;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,800,650) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = NO; [window orderFront:nil];
    DPCommandTestBrowser *browser = [DPCommandTestBrowser new]; DPCommandTestPage *original = [DPCommandTestPage new];
    DPCommandTestDelegate *delegate = [DPCommandTestDelegate new]; delegate.window = window; delegate.accepts = YES;
    DPBrowseSource *source = [DPBrowseSource new]; source.browser = browser; source.window = window;
    DPCommandBarLauncher *bar = [DPCommandBarLauncher new]; bar.commandBar = YES; bar.source = source;
    bar.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,600,200) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    bar.window.releasedWhenClosed = NO; bar.window.delegate = nil; bar.openingResult = YES; [bar.window orderFront:nil];
    NSURL *url = [NSURL URLWithString:@"https://command.example/search?q=hello"];
    NSUInteger miniCount = DPBrowseWindows.count;
    for (NSUInteger mode = 0; mode < 3; mode++) {
        source.contents = mode == 2 ? nil : original; source.delegate = mode == 2 ? nil : delegate; source.browserDelegate = mode == 1 ? nil : delegate;
        __block BOOL done = NO, opened = NO;
        DPCommandBarOpenTab(bar, url, ^(BOOL result) { done = YES; opened = result; });
        NSCAssert(done && opened && browser.lastPage.nativeView.window == window && delegate.guarded
            && [browser.lastPage.navigationController.loaded isEqual:url], @"normal, source-delegate and page-less paths adopt directly into the source window");
        NSCAssert(browser.foreground && !browser.untracked && DPBrowseWindows.count == miniCount && !DPCommandBarIsAdopting(),
            @"tab creation is tracked, foreground, guarded and never creates a Mini window");
        [browser.lastPage close];
    }
    delegate.palette = bar.window; delegate.hidesPalette = YES;
    __block BOOL hiddenDone = NO, hiddenOpened = NO;
    DPCommandBarOpenTab(bar, url, ^(BOOL result) { hiddenDone = YES; hiddenOpened = result; });
    NSCAssert(hiddenDone && hiddenOpened && !bar.window.visible && !browser.lastPage.closed
        && browser.lastPage.nativeView.window == window, @"native adoption remains successful when Dia hides the palette during handoff");
    [browser.lastPage close]; delegate.hidesPalette = NO; delegate.palette = nil; [bar.window orderFront:nil];
    delegate.accepts = NO;
    __block BOOL done = NO, opened = YES;
    DPCommandBarOpenTab(bar, url, ^(BOOL result) { done = YES; opened = result; });
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.8]];
    NSCAssert(done && !opened && browser.lastPage.closed, @"a rejected handoff closes the orphan page");
    done = NO; DPCommandBarOpenTab(bar, url, ^(BOOL result) { done = YES; opened = result; });
    DPCommandBar.on = NO; [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    NSCAssert(done && !opened && browser.lastPage.closed, @"canceling a pending handoff cleans up its orphan");
    DPCommandBar.on = YES; [window close]; DPCommandTestPage *last = browser.lastPage;
    done = NO; DPCommandBarOpenTab(bar, url, ^(BOOL result) { done = YES; opened = result; });
    NSCAssert(done && !opened && browser.lastPage == last, @"a closed source window cannot allocate a new page");
    [bar.window close]; DPCommandBar.on = enabled;
}
