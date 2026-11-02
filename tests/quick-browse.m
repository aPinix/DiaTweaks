// Real AppKit code with stand-ins for Dia's private page and tab APIs.
#import "Patches/DiaMini/Browse/QuickBrowse.h"
#import "Patches/Peek/Indicator.h"
#import "Patches/Peek/Button.h"
#import "Patches/DiaMini/Browse/Launcher.h"
#import "mini-shortcuts.h"

void DPTestPeekOrigin(DPPeekCard *peek);
void DPTestMiniLauncherLayout(DPMiniLauncher *launcher);
void DPTestSiteSearch(DPBrowseSource *source);
void DPTestCommandBar(DPBrowseSource *source);

DPPatch DPDiaMini = {.on = YES};
DPPatch DPDiaMiniExternal;
static NSUInteger closed, promoted, loads;
static NSUInteger tabCloseClicks;
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
- (void)adopt:(FixtureContents *)contents {
    NSView *pane=DPFindView(self.destination.contentView,^BOOL(NSView *v){ return DPIsKind(v,DPDiaContentPane); });
    [pane ?: self.destination.contentView addSubview:contents.nativeView]; promoted++;
}
- (NSInteger)webContents:(id)c decidePolicyForNavigationAction:(id)a { return 1; }
- (BOOL)webContents:(id)c willShowContextMenu:(NSMenu *)m withElement:(id)e { return YES; }
- (void)webContents:(id)s didCreateNewWebContent:(FixtureContents *)c targetURL:(NSURL *)u disposition:(NSInteger)d {
    NSCAssert(d == 2 || d == 9, @"tab or split disposition");
    if (self.acceptPromotion) [self adopt:c];
}
- (void)webContents:(id)c didCloseWithSessionID:(id)s {}
- (void)browser:(id)b didRestoreWebContents:(id)c withSessionId:(id)s {}
- (void)browser:(id)b didCreateNewWebContents:(FixtureContents *)c isActive:(BOOL)a {
    if (self.acceptPromotion) [self adopt:c];
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
@interface FixtureTabContent : NSView
@property(strong) NSButton *closeButton;
@property(strong) NSTextField *titleLabel;
@end
@implementation FixtureTabContent
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self=[super initWithFrame:frame])) {
        _closeButton=[NSButton buttonWithTitle:@"×" target:self action:@selector(closeTab:)];
        _closeButton.accessibilityIdentifier=@"tabCloseButton"; [self addSubview:_closeButton];
        _titleLabel=[NSTextField labelWithString:@"A long tab title that must leave room for the close button and Peek favicon"];
        _titleLabel.lineBreakMode=NSLineBreakByTruncatingTail; [self addSubview:_titleLabel];
    }
    return self;
}
- (void)layout {
    [super layout];
    self.closeButton.frame=NSMakeRect(NSWidth(self.bounds)-24,10,16,16);
    self.titleLabel.frame=NSMakeRect(30,10,MAX(0,NSWidth(self.bounds)-(self.closeButton.hidden?38:58)),16);
}
- (void)closeTab:(id)sender { tabCloseClicks++; }
@end
@interface FixtureTab : NSView
@property BOOL selected;
@end
@implementation FixtureTab
- (void)layout {
    [super layout];
    for (NSView *child in self.subviews) if (DPIsKind(child,DPDiaTabContentView)) {
        child.frame=NSInsetRect(self.bounds,6,0); child.needsLayout=YES;
    }
}
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
static void drainUntil(BOOL (^ready)(void)) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:1];
    while (!ready() && deadline.timeIntervalSinceNow>0) drain(0.01);
}
static DPBrowseWindow *mini(void) { return DPBrowseWindows.anyObject; }

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        NSString *shortcutDomain = [@"com.diapatches.shortcut-fixture." stringByAppendingString:NSUUID.UUID.UUIDString];
        setenv("DIATWEAKS_DOMAIN", shortcutDomain.UTF8String, 1);
        alias(DPFixtureShortcutPage.class,"DPPageView");
        alias(FixtureContents.class,DPDiaWebContents); alias(FixtureBrowser.class,DPDiaBrowser);
        alias(FixtureBrowserApplication.class,DPDiaBrowserApplication);
        alias(FixtureBrowser.class,DPDiaBrowserContext); alias(FixtureConfig.class,DPDiaWebContentsConfiguration);
        alias(FixtureDelegate.class,DPDiaTablessDelegate); alias(FixtureDelegate.class,DPDiaBrowserDelegate);
        alias(FixtureDelegate.class,DPDiaWebContent); alias(NSView.class,DPDiaContentPane);
        alias(NSView.class,DPDiaContentContainer);
        alias(FixtureHistoryOptions.class,"ArcHistoryQueryOptions");
        alias(FixtureTab.class,DPDiaTabView); alias(NSView.class,DPDiaFavoriteTab);
        alias(FixtureTabContent.class,DPDiaTabContentView);
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
        DPTestMiniShortcuts();

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
        FixtureTabContent *tabContent=[[objc_getClass(DPDiaTabContentView) alloc] initWithFrame:NSMakeRect(6,0,208,37)];
        [row addSubview:tabContent]; row.needsLayout=YES; [row layoutSubtreeIfNeeded];
        [window.contentView addSubview:row];
        NSView *browserFrame=[[objc_getClass(DPDiaContentContainer) alloc] initWithFrame:NSMakeRect(220,0,780,700)];
        NSView *pane = [[objc_getClass(DPDiaContentPane) alloc] initWithFrame:browserFrame.bounds];
        pane.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
        [browserFrame addSubview:pane]; [window.contentView addSubview:browserFrame];
        NSView *flyout=[[NSView alloc] initWithFrame:NSMakeRect(0,0,300,200)];
        NSButton *sidebarButton=[NSButton buttonWithTitle:@"Sidebar action" target:nil action:nil];
        sidebarButton.frame=NSMakeRect(240,40,50,30); [flyout addSubview:sidebarButton];
        [window.contentView addSubview:flyout positioned:NSWindowAbove relativeTo:browserFrame];
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
        DPBrowseSuggestions(source,@"",^(NSArray *items){ suggestions=items; }); drainUntil(^BOOL{ return suggestions != nil; });
        NSCAssert(suggestions.count==1 && [((DPBrowseSuggestion *)suggestions[0]).title isEqual:@"Recently visited"],@"empty launcher reads real profile history");
        DPBrowseRemember(source,url,@"Last Mini result");
        DPBrowseSource *other=[DPBrowseSource new]; other.browser=[FixtureBrowser new];
        NSCAssert(DPBrowseRecents(source).count==1 && !DPBrowseRecents(other).count,@"recent fallback stays with its source profile");
        DPBrowseShowLauncher(); DPMiniLauncher *launcher=DPCurrentMiniLauncher;
        drainUntil(^BOOL{ return launcher.suggestions.count==2; });
        NSCAssert(launcher && launcher.source.browser==browser && launcher.suggestions.count==2,
            @"temporary search box shows recent results (launcher=%@ source=%@ expected=%@ count=%lu current=%@)",
            launcher,launcher.source.browser,browser,launcher.suggestions.count,DPCurrentMiniLauncher);
        NSCAssert(launcher.table.selectedRow==0,@"favicon updates preserve the highlighted result");
        DPTestMiniLauncherLayout(launcher);
        NSWindow *launcherShadow=launcher.shadowWindow;
        launcher.search.stringValue=@"first"; [launcher query]; launcher.search.stringValue=@"second"; [launcher query]; drain(0.03);
        NSCAssert([launcher.suggestions.firstObject.url.path isEqual:@"/second"],@"out-of-order suggestions cannot replace the latest query");
        [launcher choose:nil];
        NSCAssert(!DPCurrentMiniLauncher && DPBrowseWindows.count==1,@"Enter replaces the launcher with a compact result window");
        NSCAssert(!launcherShadow.visible && !launcherShadow.parentWindow,@"closing the launcher leaves no shadow window behind");
        NSCAssert([((FixtureNavigation *)mini().contents.navigationController).loaded.path isEqual:@"/second"],@"selected native result opened");
        [mini() close];
        DPBrowseShowLauncher(); launcher=DPCurrentMiniLauncher;
        [launcher control:launcher.search textView:[NSTextView new] doCommandBySelector:@selector(cancelOperation:)];
        NSCAssert(!DPCurrentMiniLauncher,@"Escape dismisses temporary search");
        NSCAssert(DPNewMiniItem.keyEquivalentModifierMask==(NSEventModifierFlagOption|NSEventModifierFlagCommand),@"default global chord advertised");
        DPDiaMiniExternal.on=NO; [applicationDelegate application:NSApp openURLs:@[url]];
        NSCAssert(applicationDelegate.received.count==1 && !DPBrowseWindows.count,@"external-link preference off preserves normal opening");
        DPDiaMiniExternal.on=YES;
        NSURL *fileURL=[NSURL fileURLWithPath:@"/tmp/fixture"];
        [applicationDelegate application:NSApp openURLs:@[url,fileURL]];
        NSCAssert(DPBrowseWindows.count==1 && [applicationDelegate.received isEqual:@[fileURL]],@"only external web links use Mini when enabled");
        [mini() close]; DPDiaMiniExternal.on=NO;
        [window makeKeyAndOrderFront:nil];
        FixtureAction *action=[FixtureAction new]; action.url=url; action.navigationDisposition=5;
        NSPoint clicked=NSMakePoint(147,523);
        DPPeekRememberClick(window,NSEventModifierFlagShift,clicked);
        NSCAssert([delegate webContents:sourcePage decidePolicyForNavigationAction:action]==0,@"remember Shift after the input event ends");
        drainUntil(^BOOL{ return DPPeekCardIn(window) != nil; });
        NSCAssert(DPPeekCardIn(window),@"remembered click opens the preview");
        NSCAssert(NSEqualPoints(DPPeekCardIn(window).clickPointInWindow,clicked),@"navigation uses the original mouse-down location, not the later pointer position");
        NSCAssert(!DPPeekHasRecentClick(window),@"a navigation consumes its remembered click");
        [DPPeekCardIn(window) close:0]; drainUntil(^BOOL{ return DPPeekCardIn(window) == nil; });
        DPPeekRememberClick(window,NSEventModifierFlagShift|NSEventModifierFlagCommand,clicked);
        NSCAssert([delegate webContents:sourcePage decidePolicyForNavigationAction:action]==1,@"Command-Shift is left to Dia");
        action.url=[NSURL URLWithString:@"mailto:test@example.com"];
        DPPeekRememberClick(window,NSEventModifierFlagShift,clicked);
        NSCAssert([delegate webContents:sourcePage decidePolicyForNavigationAction:action]==1 && !DPPeekCardIn(window),@"special links keep Dia's normal policy");
        action.url=url; DPPeekRememberClick(window,0,clicked);
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
        NSCAssert(peek && peek.pane == pane && peek.surface==browserFrame && peek.superview==browserFrame.superview,@"Peek tracks the complete browser-content frame");
        NSCAssert(peek.subviews.count==2 && peek.backdropLayer==browserFrame.layer,@"the content frame itself fades without a blur or painted overlay");
        CAAnimationGroup *backdrop=(id)[peek.backdropLayer animationForKey:@"DiaTweaks.Peek.Depth"];
        CABasicAnimation *contentFade=(id)backdrop.animations.lastObject;
        NSCAssert([contentFade.keyPath isEqual:@"opacity"] && fabs([contentFade.toValue doubleValue]-0.2)<0.001,@"background content fades to twenty percent opacity");
        NSRect originalPeekFrame=peek.frame;
        for (NSNumber *width in @[@780, @781, @783.5, @1141, @1493]) {
            peek.frame=NSMakeRect(NSMinX(originalPeekFrame),NSMinY(originalPeekFrame),width.doubleValue,701);
            peek.needsLayout=YES; [peek layoutSubtreeIfNeeded];
            NSRect pixels=[peek convertRectToBacking:peek.card.frame];
            for (NSNumber *edge in @[@(NSMinX(pixels)),@(NSMaxX(pixels)),@(NSMinY(pixels)),@(NSMaxY(pixels))])
                NSCAssert(fabs(edge.doubleValue-round(edge.doubleValue))<0.001,@"card edges land on physical pixels at odd and fractional widths");
            NSRect clipPixels=[peek.clip convertRectToBacking:peek.clip.bounds], hostPixels=[peek.clip convertRectToBacking:peek.host.frame];
            NSCAssert(NSContainsRect(hostPixels,clipPixels) && fabs(NSWidth(hostPixels)-NSWidth(clipPixels)-2)<0.001,
                @"the web surface covers the clipped edge with a physical pixel on each side");
        }
        NSCAssert(CGColorGetAlpha(peek.clip.layer.backgroundColor)==0,@"no white backing can bleed beside the compositor's edge");
        peek.frame=originalPeekFrame; peek.needsLayout=YES; [peek layoutSubtreeIfNeeded];
        DPTestPeekOrigin(peek);
        NSPoint sidebarPoint=[window.contentView.superview convertPoint:NSMakePoint(265,55) fromView:window.contentView];
        NSView *sidebarHit=[window.contentView hitTest:sidebarPoint];
        NSCAssert(sidebarHit==sidebarButton || [sidebarHit isDescendantOf:sidebarButton],@"a revealed sidebar remains above Peek and receives clicks");
        DPPeekButton *closeControl=(id)peek.controls.subviews.firstObject;
        NSRect closeFrame=[peek convertRect:CGPathGetBoundingBox(closeControl.disc.path) fromView:closeControl];
        NSCAssert(NSWidth(closeFrame)==34 && NSMinY(closeFrame)==NSMinY(peek.card.frame)+8,@"Arc-sized circles are inset from the card's top");
        NSEvent *hover=[NSEvent enterExitEventWithType:NSEventTypeMouseEntered location:NSZeroPoint modifierFlags:0
            timestamp:0 windowNumber:window.windowNumber context:nil eventNumber:0 trackingNumber:0 userData:NULL];
        NSCAssert(hover,@"fixture hover event");
        [closeControl mouseEntered:hover];
        NSCAssert(closeControl.artwork.transform.m11>1 && [closeControl.artwork animationForKey:@"peekHoverTransform"],@"hover provides animated control feedback");
        CGFloat overhang=34*(closeControl.artwork.transform.m11-1)/2;
        for (DPPeekButton *control in peek.controls.subviews) {
            NSRect circle=CGPathGetBoundingBox(control.disc.path), symbol=CGPathGetBoundingBox(control.glyph.path);
            NSCAssert(NSContainsRect(control.bounds,NSInsetRect(circle,-overhang,-overhang)),@"every hovered circle fits inside its hit target without cropped edges");
            NSCAssert(NSMidX(circle)==NSMidX(symbol) && NSMidY(circle)==NSMidY(symbol),@"each vector symbol shares the circle's exact center");
        }
        [closeControl mouseExited:hover];
        NSCAssert(closeControl.artwork.transform.m11==1,@"exiting returns the button to its normal size");
        reduceMotion=YES; [closeControl mouseEntered:hover];
        NSCAssert(closeControl.artwork.transform.m11==1 && ![closeControl.artwork animationForKey:@"peekHoverTransform"],@"Reduce Motion keeps hover feedback stationary");
        reduceMotion=NO; [closeControl mouseExited:hover];
        NSCAssert(DPPeekSelectedTab(window.contentView)==(id)row,@"native source row found");
        NSCAssert(DPFindView(window.contentView,^BOOL(NSView *v){ return [v.accessibilityLabel isEqual:@"Peek open"]; }),@"source row shows a live badge");
        NSView *rowBadge=DPFindView(window.contentView,^BOOL(NSView *v){ return [v.accessibilityLabel isEqual:@"Peek open"]; });
        NSImageView *badgeIcon=(id)DPFindView(rowBadge,^BOOL(NSView *v){ return [v isKindOfClass:NSImageView.class]; });
        NSCAssert(NSWidth(rowBadge.frame)==24 && NSEqualRects(badgeIcon.frame,NSMakeRect(4,4,16,16)),@"the row favicon has a padded rounded tile");
        NSCAssert(NSMaxX(rowBadge.frame)==NSMaxX(row.frame)-14,@"the tile stays inside the tab's rounded end");
        NSCAssert([rowBadge hitTest:NSZeroPoint]==nil,@"the decoration leaves native tab interactions intact");
        NSRect closeRect=[window.contentView convertRect:tabContent.closeButton.bounds fromView:tabContent.closeButton];
        NSCAssert(NSMaxX(closeRect)+4<=NSMinX(rowBadge.frame),@"native close button sits left of the favicon with a gap");
        [tabContent.closeButton performClick:nil]; NSCAssert(tabCloseClicks==1,@"native close action is preserved");
        for (NSUInteger i=0;i<3;i++) { row.needsLayout=YES; [row layoutSubtreeIfNeeded]; }
        NSCAssert(NSWidth(tabContent.frame)==180,@"repeated native layouts do not consume more tab width");
        tabContent.closeButton.hidden=YES; tabContent.needsLayout=YES; [tabContent layoutSubtreeIfNeeded];
        NSRect titleRect=[window.contentView convertRect:tabContent.titleLabel.bounds fromView:tabContent.titleLabel];
        NSCAssert(NSMaxX(titleRect)<NSMinX(rowBadge.frame),@"title leaves the favicon slot free without hovering");
        tabContent.closeButton.hidden=NO; tabContent.needsLayout=YES; [tabContent layoutSubtreeIfNeeded];
        row.frame=NSMakeRect(0,620,180,32); row.needsLayout=YES; [row layoutSubtreeIfNeeded];
        NSCAssert(NSWidth(tabContent.frame)==140,@"reservation follows a narrower horizontal-size tab");
        row.frame=NSMakeRect(0,620,220,37); row.needsLayout=YES; [row layoutSubtreeIfNeeded];
        NSCAssert([peek.backdropLayer animationForKey:@"DiaTweaks.Peek.Depth"],@"background depth animation installed");
        NSCAssert(fabs(DPPeekDepth(NSMakeRect(0,0,800,600),0.975).m41-10)<0.01,@"depth anchored at center");
        beforeClose=closed; beforePromotion=promoted; NSUInteger beforeLoads=loads;
        [peek close:1];
        NSCAssert(peek.superview && promoted==beforePromotion,@"page stays in the card during expansion");
        drain(0.40);
        NSCAssert(!DPPeekCardIn(window) && promoted==beforePromotion+1 && closed==beforeClose && loads==beforeLoads,
            @"expanded page becomes a tab without reloading or closing it");
        NSCAssert(![browserFrame.layer animationForKey:@"DiaTweaks.Peek.Depth"],@"the entire content frame is restored after expansion");
        NSCAssert(!DPFindView(window.contentView,^BOOL(NSView *v){ return [v.accessibilityLabel isEqual:@"Peek open"]; }),@"source badge removed with the card");
        NSCAssert(NSWidth(tabContent.frame)==208,@"closing Peek restores the tab's full native width");

        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        peek=DPPeekCardIn(window); beforePromotion=promoted; beforeClose=closed;
        [peek close:1]; [peek close:0]; drain(0.40);
        NSCAssert(promoted==beforePromotion && closed==beforeClose+1 && !DPPeekCardIn(window),@"Escape cancels an in-flight expansion once");
        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        peek=DPPeekCardIn(window);
        CAAnimationGroup *opening=(id)[peek.card.layer animationForKey:@"peek"];
        NSValue *seed=((CABasicAnimation *)opening.animations.firstObject).fromValue;
        [peek close:0];
        CAAnimationGroup *dismiss=(id)[peek.card.layer animationForKey:@"peek"];
        NSCAssert(dismiss.duration>=0.20,@"dismissal gives the page time to fade smoothly");
        CABasicAnimation *recede=(id)dismiss.animations.firstObject;
        NSCAssert([recede.toValue isEqual:seed],@"closing returns to the same point and scale used by opening");
        NSCAssert([recede.fromValue isEqual:seed],@"closing before the first display tick does not jump to full size");
        drain(0.10); NSCAssert(peek.superview,@"the live page remains attached during the close transition");
        drainUntil(^BOOL{ return peek.superview == nil; });
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
        [DPPeekCardIn(window) close:0]; drainUntil(^BOOL{ return DPPeekCardIn(window) == nil; });

        reduceMotion=YES;
        DPPeekOpen(window,url,NSMakePoint(500,500),delegate,sourcePage);
        peek=DPPeekCardIn(window);
        CAAnimationGroup *background=(id)[peek.backdropLayer animationForKey:@"DiaTweaks.Peek.Depth"];
        for (CABasicAnimation *a in background.animations) NSCAssert(![a.keyPath isEqual:@"transform"],@"Reduce Motion fades the content without moving it");
        CAAnimationGroup *group=(id)[peek.card.layer animationForKey:@"peek"];
        for (CABasicAnimation *a in group.animations) NSCAssert(![a.keyPath isEqual:@"transform"],@"Reduce Motion uses opacity");
        DPDiaMini.on=NO; DPBrowseApply(&DPDiaMini);
        NSCAssert(DPPeekCardIn(window) && !DPBrowseWindows.count && DPNewMiniItem.hidden,@"Mini switch leaves Peek open");
        [peek close:0]; drain(0.15);
        NSCAssert(!DPPeekCardIn(window),@"reduced-motion cleanup");
        extern void DPTestInputBehavior(DPBrowseSource *source);
        DPTestInputBehavior(source);
        DPTestSiteSearch(source);
        DPTestCommandBar(source);
        [window close];
        [NSUserDefaults.standardUserDefaults removePersistentDomainForName:shortcutDomain];
        puts("PASS: Mini, scoped site search, configurable Command Bar and native tab handoff; Peek motion, badges and Reduce Motion");
    }
}
