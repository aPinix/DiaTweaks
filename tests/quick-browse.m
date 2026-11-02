// Real AppKit code with stand-ins for Dia's private page and tab APIs.
#import "Commands/QuickBrowse/QuickBrowse.h"
#import "Patches/Peek/Indicator.h"
#import "Commands/QuickBrowse/Launcher.h"

DPPatch DPDiaMini = {.on = YES};
DPPatch DPDiaMiniExternal;
static NSUInteger closed, promoted, loads;
static BOOL reduceMotion;

@interface FixtureHistoryItem : NSObject
@property(strong) NSURL *url;
@property(copy) NSString *title;
@end
@implementation FixtureHistoryItem
@end
@interface FixtureHistoryOptions : NSObject
@property(copy) NSString *searchText;
@property int maxResults;
@end
@implementation FixtureHistoryOptions
@end
@interface FixtureHistory : NSObject
@end
@implementation FixtureHistory
- (void)searchHistory:(id)options completion:(void (^)(id))completion {
    FixtureHistoryItem *item=[FixtureHistoryItem new]; item.url=[NSURL URLWithString:@"https://recent.example/"]; item.title=@"Recently visited";
    completion(@[item]);
}
@end
@interface FixtureContext : NSObject
@property(strong) FixtureHistory *history;
@end
@implementation FixtureContext
- (instancetype)init { if ((self=[super init])) _history=[FixtureHistory new]; return self; }
- (void)favicon:(NSURL *)url completion:(void (^)(id))completion { completion([NSImage imageWithSystemSymbolName:@"globe" accessibilityDescription:nil]); }
@end

@interface FixtureConfig : NSObject
@property BOOL foreground, untracked;
@end
@implementation FixtureConfig
@end
@interface FixtureNavigation : NSObject
@property(strong) NSURL *loaded;
@end
@implementation FixtureNavigation
- (id)load:(NSURL *)url initiatorOrigin:(id)origin { self.loaded = url; loads++; return nil; }
- (id)goBack { return nil; }
- (id)goForward { return nil; }
- (id)reload { return nil; }
@end
@interface FixtureContents : NSObject <DPBrowseContents, DPPeekPage>
@property(strong) NSView *nativeView;
@property(strong) NSURL *url;
@property(strong) NSString *title;
@property(strong) NSImage *favicon;
@property(strong) FixtureNavigation *navigationController;
@property(weak) id UIDelegate, navigationDelegate;
@property BOOL hasFocus, canGoBack, canGoForward;
@property NSInteger visibility;
@end
@implementation FixtureContents
- (instancetype)init {
    if ((self = [super init])) {
        _nativeView = [[NSView alloc] initWithFrame:NSMakeRect(0,0,700,500)];
        _navigationController = [FixtureNavigation new];
        _url = [NSURL URLWithString:@"https://example.com/"]; _title = @"Example";
    }
    return self;
}
- (NSView *)createPaneHostView { return [NSView new]; }
- (void)attachToPaneHostView:(NSView *)view { [view addSubview:self.nativeView]; }
- (void)detachFromPaneHostView:(NSView *)view { [self.nativeView removeFromSuperview]; }
- (void)close { closed++; [self.nativeView removeFromSuperview]; }
- (void)bootstrapRendering {}
- (void)bootstrapRenderingComplete {}
@end
@interface FixtureDelegate : NSObject
@property(weak) NSWindow *destination;
@property BOOL acceptPromotion;
@end
@implementation FixtureDelegate
- (NSInteger)webContents:(id)c decidePolicyForNavigationAction:(id)a { return 1; }
- (BOOL)webContents:(id)c willShowContextMenu:(NSMenu *)m withElement:(id)e { return YES; }
- (void)webContents:(id)s didCreateNewWebContent:(FixtureContents *)c targetURL:(NSURL *)u disposition:(NSInteger)d {
    NSCAssert(d == 2 || d == 9, @"tab or split disposition");
    if (self.acceptPromotion) { [self.destination.contentView addSubview:c.nativeView]; promoted++; }
}
- (void)webContents:(id)c didCloseWithSessionID:(id)s {}
- (void)browser:(id)b didRestoreWebContents:(id)c withSessionId:(id)s {}
- (void)browser:(id)b didCreateNewWebContents:(FixtureContents *)c isActive:(BOOL)a {
    if (self.acceptPromotion) { [self.destination.contentView addSubview:c.nativeView]; promoted++; }
}
@end
@interface FixtureBrowser : NSObject
@property(strong) FixtureContext *context;
@property(weak) id delegate;
@property(copy) NSString *windowIdentifier;
@end
@implementation FixtureBrowser
- (instancetype)init { if ((self=[super init])) _context=[FixtureContext new]; return self; }
- (id)createWebContents:(id)config { return [objc_getClass(DPDiaWebContents) new]; }
- (void)takeOwnershipOfWebContents:(id)contents {}
- (void)setWindow:(NSWindow *)window {}
- (BOOL)autocomplete:(NSString *)text cursorPosition:(int)position preventInlineAutocomplete:(BOOL)prevent startFresh:(BOOL)fresh
             keyword:(NSString *)keyword error:(NSError **)error completion:(void (^)(id))completion {
    FixtureHistoryItem *item=[FixtureHistoryItem new];
    NSURLComponents *url=[NSURLComponents componentsWithString:@"https://query.example/"]; url.path=[@"/" stringByAppendingString:text];
    item.url=url.URL; item.title=[@"Native " stringByAppendingString:text]; completion(@[item]); return YES;
}
@end
@interface FixtureBrowserApplication : NSObject
@end
@implementation FixtureBrowserApplication
- (id)createBrowser:(id)context withDelegate:(id)delegate forWindow:(NSString *)identifier {
    FixtureBrowser *browser=[objc_getClass(DPDiaBrowser) new];
    browser.context=context; browser.delegate=delegate; browser.windowIdentifier=identifier; return browser;
}
@end
@interface FixtureTab : NSView
@property BOOL selected;
@end
@implementation FixtureTab
- (NSString *)accessibilityRole { return NSAccessibilityRadioButtonRole; }
- (NSString *)accessibilityIdentifier { return @"tab"; }
- (id)accessibilityValue { return @(self.selected); }
- (BOOL)isAccessibilityElement { return YES; }
@end
@interface FixtureAction : NSObject
@property NSInteger navigationDisposition;
@property(strong) NSURL *url;
@end
@implementation FixtureAction
@end
@interface FixtureApplicationDelegate : NSObject <NSApplicationDelegate>
@property(copy) NSArray *received;
@end
@implementation FixtureApplicationDelegate
- (void)application:(NSApplication *)app openURLs:(NSArray *)urls { self.received=urls; }
@end

static BOOL reduced(id self, SEL cmd) { return reduceMotion; }
static void alias(Class base, const char *name) {
    Class cls = objc_allocateClassPair(base,name,0); NSCAssert(cls,@"unique class"); objc_registerClassPair(cls);
}
static void drain(double seconds) { [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]]; }
static DPBrowseWindow *mini(void) { return DPBrowseWindows.anyObject; }

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        alias(FixtureContents.class,DPDiaWebContents); alias(FixtureBrowser.class,DPDiaBrowser);
        alias(FixtureBrowserApplication.class,DPDiaBrowserApplication);
        alias(FixtureBrowser.class,DPDiaBrowserContext); alias(FixtureConfig.class,DPDiaWebContentsConfiguration);
        alias(FixtureDelegate.class,DPDiaTablessDelegate); alias(FixtureDelegate.class,DPDiaBrowserDelegate);
        alias(FixtureDelegate.class,DPDiaWebContent); alias(NSView.class,DPDiaContentPane);
        alias(FixtureHistoryOptions.class,"ArcHistoryQueryOptions");
        alias(FixtureTab.class,DPDiaTabView); alias(NSView.class,DPDiaFavoriteTab);
        alias(NSView.class,"FixtureSelectionOutlineView");
        DPHookClass(NSWorkspace.class,@selector(accessibilityDisplayShouldReduceMotion),(IMP)reduced);
        NSApp.mainMenu = [NSMenu new];
        FixtureApplicationDelegate *applicationDelegate=[FixtureApplicationDelegate new]; NSApp.delegate=applicationDelegate;
        NSMenuItem *file = [[NSMenuItem alloc] initWithTitle:@"File" action:nil keyEquivalent:@""];
        file.submenu = [[NSMenu alloc] initWithTitle:@"File"]; [NSApp.mainMenu addItem:file];
        DPPeek.on = YES; DPDiaMini.on=NO;
        DPPeek.install(); DPInstallQuickBrowse(); DPInstallQuickBrowse();
        [NSNotificationCenter.defaultCenter postNotificationName:NSApplicationDidFinishLaunchingNotification object:NSApp];
        DPDiaMini.on=YES;
        NSCAssert(file.submenu.numberOfItems == 1 && DPBrowseCompatible(),@"one Mini menu and supported native APIs");

        for (NSString *bad in @[@"javascript:alert(1)",@"data:text/html,x",@"file:///tmp/x",@"dia://settings",@"ftp://example.com",@""])
            NSCAssert(!DPBrowseURL(bad) && !DPBrowseAddress(bad),@"reject unsafe or unsupported navigation %@",bad);
        NSCAssert([DPBrowseAddress(@"example.com").host isEqual:@"example.com"],@"bare host");
        NSCAssert([DPBrowseAddress(@"localhost:3000/a").host isEqual:@"localhost"],@"host and port");
        NSCAssert([DPBrowseAddress(@"a & b ü").query containsString:@"q="],@"search escaping");
        NSRect screen = NSMakeRect(-1440,-100,1280,800);
        NSCAssert(NSContainsRect(screen,DPBrowseFrame(NSMakeRect(-1600,-200,1400,1100),screen)),@"secondary display");
        NSRect launcherFrame=DPBrowseLauncherFrame(screen,330);
        NSCAssert(NSContainsRect(screen,launcherFrame) && NSMaxX(launcherFrame)==NSMaxX(screen)-16
            && NSMaxY(launcherFrame)==NSMaxY(screen)-16,@"launcher anchors at the active screen's top-right, including a secondary display");

        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(60,100,1000,700)
            styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
        window.releasedWhenClosed = NO; [window orderFront:nil];
        window.accessibilityIdentifier=@"bigBrowserWindow-fixture";
        window.identifier=@"fixture";
        FixtureTab *row = [[objc_getClass(DPDiaTabView) alloc] initWithFrame:NSMakeRect(0,620,220,37)]; row.selected=YES;
        [window.contentView addSubview:row];
        NSView *pane = [[objc_getClass(DPDiaContentPane) alloc] initWithFrame:NSMakeRect(220,0,780,700)];
        [window.contentView addSubview:pane];
        FixtureBrowser *browser = [objc_getClass(DPDiaBrowser) new];
        FixtureContents *sourcePage = [browser createWebContents:[FixtureConfig new]];
        FixtureDelegate *delegate = [objc_getClass(DPDiaWebContent) new]; delegate.destination = window; delegate.acceptPromotion = YES;
        [sourcePage setUIDelegate:delegate]; [sourcePage attachToPaneHostView:pane];
        DPBrowseSource *source = DPBrowseSourceFor(sourcePage);
        NSCAssert(source.browser == browser && DPPeekCanOpen(sourcePage),@"both features keep the source factory/profile");

        FixtureContents *restored=[objc_getClass(DPDiaWebContents) new];
        FixtureDelegate *restorer=[objc_getClass(DPDiaBrowserDelegate) new];
        [restorer browser:browser didRestoreWebContents:restored withSessionId:@42];
        NSCAssert(DPPeekCanOpen(restored),@"restored pages retain their factory");

        NSURL *url = [NSURL URLWithString:@"https://example.org/"];
        __block NSArray *suggestions;
        DPBrowseSuggestions(source,@"",^(NSArray *items){ suggestions=items; }); drain(0.02);
        NSCAssert(suggestions.count==1 && [((DPBrowseSuggestion *)suggestions[0]).title isEqual:@"Recently visited"],@"empty launcher reads real profile history");
        DPBrowseRemember(source,url,@"Last Mini result");
        DPBrowseSource *other=[DPBrowseSource new]; other.browser=[FixtureBrowser new];
        NSCAssert(DPBrowseRecents(source).count==1 && !DPBrowseRecents(other).count,@"recent fallback stays with its source profile");
        DPBrowseShowLauncher(); DPMiniLauncher *launcher=DPCurrentMiniLauncher; drain(0.03);
        NSCAssert(launcher && launcher.source.browser==browser && launcher.suggestions.count==2,@"temporary search box shows recent results");
        NSCAssert(launcher.table.selectedRow==0,@"favicon updates preserve the highlighted result");
        launcher.search.stringValue=@"first"; [launcher query]; launcher.search.stringValue=@"second"; [launcher query]; drain(0.03);
        NSCAssert([launcher.suggestions.firstObject.url.path isEqual:@"/second"],@"out-of-order suggestions cannot replace the latest query");
        [launcher choose:nil];
        NSCAssert(!DPCurrentMiniLauncher && DPBrowseWindows.count==1,@"Enter replaces the launcher with a compact result window");
        NSCAssert([((FixtureNavigation *)mini().contents.navigationController).loaded.path isEqual:@"/second"],@"selected native result opened");
        [mini() close];
        DPBrowseShowLauncher(); launcher=DPCurrentMiniLauncher;
        [launcher control:launcher.search textView:[NSTextView new] doCommandBySelector:@selector(cancelOperation:)];
        NSCAssert(!DPCurrentMiniLauncher,@"Escape dismisses temporary search");
        NSCAssert(DPNewMiniItem.keyEquivalentModifierMask==(NSEventModifierFlagControl|NSEventModifierFlagOption|NSEventModifierFlagCommand),@"requested global chord advertised");
        DPDiaMiniExternal.on=NO; [applicationDelegate application:NSApp openURLs:@[url]];
        NSCAssert(applicationDelegate.received.count==1 && !DPBrowseWindows.count,@"external-link preference off preserves normal opening");
        DPDiaMiniExternal.on=YES;
        NSURL *fileURL=[NSURL fileURLWithPath:@"/tmp/fixture"];
        [applicationDelegate application:NSApp openURLs:@[url,fileURL]];
        NSCAssert(DPBrowseWindows.count==1 && [applicationDelegate.received isEqual:@[fileURL]],@"only external web links use Mini when enabled");
        [mini() close]; DPDiaMiniExternal.on=NO;
        [window makeKeyAndOrderFront:nil];
        FixtureAction *action=[FixtureAction new]; action.url=url; action.navigationDisposition=5;
        DPPeekRememberClick(window,NSEventModifierFlagShift);
        NSCAssert([delegate webContents:sourcePage decidePolicyForNavigationAction:action]==0,@"remember Shift after the input event ends");
        drain(0.02);
        NSCAssert(DPPeekCardIn(window),@"remembered click opens the preview");
        [DPPeekCardIn(window) close:0]; drain(0.25);
        DPPeekRememberClick(window,NSEventModifierFlagShift|NSEventModifierFlagCommand);
        NSCAssert([delegate webContents:sourcePage decidePolicyForNavigationAction:action]==1,@"Command-Shift is left to Dia");
        action.url=[NSURL URLWithString:@"mailto:test@example.com"];
        DPPeekRememberClick(window,NSEventModifierFlagShift);
        NSCAssert([delegate webContents:sourcePage decidePolicyForNavigationAction:action]==1 && !DPPeekCardIn(window),@"special links keep Dia's normal policy");
        action.url=url; DPPeekRememberClick(window,0);
        NSCAssert(DPBrowseShow(url,source),@"Mini opens");
        NSCAssert(!mini().window.parentWindow && mini().source.browser == browser,@"independent Mini with same profile");
        NSCAssert([mini().address.stringValue isEqual:url.absoluteString],@"address populated before first refresh");
        NSUInteger beforeClose = closed, beforePromotion = promoted;
        [mini() promote:nil]; drain(0.65);
        NSCAssert(!DPBrowseWindows.count && promoted == beforePromotion+1 && closed == beforeClose,@"Mini hands over the live page");
        NSWindow *emptyWindow=[[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,900,600)
            styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
        emptyWindow.releasedWhenClosed=NO; emptyWindow.identifier=@"fixture-empty";
        emptyWindow.accessibilityIdentifier=@"bigBrowserWindow-fixture-empty"; [emptyWindow makeKeyAndOrderFront:nil];
        FixtureDelegate *browserDelegate=[objc_getClass(DPDiaBrowserDelegate) new];
        browserDelegate.destination=emptyWindow; browserDelegate.acceptPromotion=YES;
        FixtureBrowserApplication *application=[objc_getClass(DPDiaBrowserApplication) new];
        FixtureBrowser *emptyBrowser=[application createBrowser:[FixtureContext new] withDelegate:browserDelegate forWindow:@"fixture-empty"];
        // The fixture runs without activating an app; test the window association directly.
        // Window ordering is checked in the isolated real Dia app.
        DPBrowseSource *emptySource=DPBrowseFallbackSource(emptyWindow);
        NSCAssert(emptySource.browser==emptyBrowser && !emptySource.contents && DPBrowseSourceUsable(emptySource),@"a native New Tab supplies a page-less profile source");
        NSCAssert(DPBrowseShow(url,emptySource),@"Mini opens from a native New Tab");
        beforePromotion=promoted; beforeClose=closed;
        [mini() promote:nil]; drain(0.65);
        NSCAssert(!DPBrowseWindows.count && promoted==beforePromotion+1 && closed==beforeClose,@"browser delegate adopts a live Mini without a source webpage");
        [emptyWindow close]; [window makeKeyAndOrderFront:nil];
        NSCAssert(DPBrowseShow(url,source),@"Mini reopens");

        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        DPPeekCard *peek = DPPeekCardIn(window);
        NSCAssert(peek && peek.pane == pane && peek.superview == window.contentView,@"Peek covers the page only");
        NSCAssert(DPPeekSelectedTab(window.contentView)==(id)row,@"native source row found");
        NSCAssert(DPFindView(window.contentView,^BOOL(NSView *v){ return [v.accessibilityLabel isEqual:@"Peek open"]; }),@"source row shows a live badge");
        NSCAssert([peek.backdropLayer animationForKey:@"DiaTweaks.Peek.Depth"],@"background depth animation installed");
        NSCAssert(fabs(DPPeekDepth(NSMakeRect(0,0,800,600),0.975).m41-10)<0.01,@"depth anchored at center");
        beforeClose=closed; beforePromotion=promoted; NSUInteger beforeLoads=loads;
        [peek close:1];
        NSCAssert(peek.superview && promoted==beforePromotion,@"page stays in the card during expansion");
        drain(0.40);
        NSCAssert(!DPPeekCardIn(window) && promoted==beforePromotion+1 && closed==beforeClose && loads==beforeLoads,
            @"expanded page becomes a tab without reloading or closing it");
        NSCAssert(![pane.layer animationForKey:@"DiaTweaks.Peek.Depth"],@"background restored after expansion");
        NSCAssert(!DPFindView(window.contentView,^BOOL(NSView *v){ return [v.accessibilityLabel isEqual:@"Peek open"]; }),@"source badge removed with the card");

        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        peek=DPPeekCardIn(window); beforePromotion=promoted; beforeClose=closed;
        [peek close:1]; [peek close:0]; drain(0.40);
        NSCAssert(promoted==beforePromotion && closed==beforeClose+1 && !DPPeekCardIn(window),@"Escape cancels an in-flight expansion once");
        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        peek=DPPeekCardIn(window); [peek close:0]; drain(0.30);
        NSCAssert(peek.controls.alphaValue==0 && !peek.superview,@"late opening callback cannot resurrect controls");

        NSRect tab=NSMakeRect(10,20,300,37), pin=NSMakeRect(10,20,64,41);
        NSCAssert(NSMaxX(DPPeekIndicatorFrame(tab,NO,YES))<NSMaxX(tab),@"row badge sits inside right edge");
        NSCAssert(NSMaxX(DPPeekIndicatorFrame(pin,YES,YES))>NSMaxX(pin)
            && NSMinY(DPPeekIndicatorFrame(pin,YES,YES))<NSMinY(pin),@"pinned badge overlaps upper right");
        row.selected=NO;
        NSView *favorite=[[objc_getClass(DPDiaFavoriteTab) alloc] initWithFrame:NSMakeRect(10,660,64,41)];
        NSView *selection=[[objc_getClass("FixtureSelectionOutlineView") alloc] initWithFrame:favorite.bounds];
        [favorite addSubview:selection]; [window.contentView addSubview:favorite];
        NSCAssert(DPPeekSelectedTab(window.contentView)==(id)favorite,@"icon-only favorite found without a tab accessibility value");
        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        NSView *badge=DPFindView(window.contentView,^BOOL(NSView *v){ return [v.accessibilityLabel isEqual:@"Peek open"]; });
        NSCAssert(badge && NSMaxX(badge.frame)>NSMaxX(favorite.frame),@"favorite badge overlaps the tile edge");
        [DPPeekCardIn(window) close:0]; drain(0.25);

        reduceMotion=YES;
        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        peek=DPPeekCardIn(window);
        NSCAssert(!peek.backdropLayer,@"Reduce Motion avoids moving the background");
        CAAnimationGroup *group=(id)[peek.card.layer animationForKey:@"peek"];
        for (CABasicAnimation *a in group.animations) NSCAssert(![a.keyPath isEqual:@"transform"],@"Reduce Motion uses opacity");
        DPDiaMini.on=NO; DPBrowseApply(&DPDiaMini);
        NSCAssert(DPPeekCardIn(window) && !DPBrowseWindows.count && DPNewMiniItem.hidden,@"Mini switch leaves Peek open");
        [peek close:0]; drain(0.15);
        NSCAssert(!DPPeekCardIn(window),@"reduced-motion cleanup");
        [window close];
        puts("PASS: Mini launcher, profile history, query ordering, external-link preference and handoff; Peek motion, interruption, badges and Reduce Motion");
    }
}
