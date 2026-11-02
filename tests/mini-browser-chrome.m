#import "Patches/DiaMini/Browse/BrowserToolbar.h"
void DPTestMiniBrowserProfiles(DPBrowseWindow *owner, DPBrowseSource *destination);

static char DPChromeDelegateKey;
static DPBrowseSource *DPChromeDestination(DPBrowseSource *source, NSWindow *window, BOOL sameProfile, BOOL accepts) {
    DPBrowseSource *destination = [DPBrowseSource new]; destination.window = window;
    destination.browser = [[source.browser class] new];
    if (sameProfile) [destination.browser setValue:DPBrowseContext(source) forKey:@"context"];
    id delegate = [objc_getClass(DPDiaBrowserDelegate) new];
    [delegate setValue:window forKey:@"destination"]; [delegate setValue:@(accepts) forKey:@"acceptPromotion"];
    // The fixture source stores delegates weakly, matching the native ownership model.
    objc_setAssociatedObject(destination.browser, &DPChromeDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    destination.browserDelegate = delegate; return destination;
}

void DPTestMiniBrowserChrome(DPBrowseSource *source) {
    NSString *sourceIdentifier = source.window.accessibilityIdentifier;
    source.window.accessibilityIdentifier = @"bigBrowserWindow-mini-source";
    NSRect large = DPBrowseFrame(NSMakeRect(200,100,1400,1000), NSMakeRect(0,0,1920,1080));
    NSCAssert(NSWidth(large) == 1280 && NSHeight(large) == 950, @"Mini browser uses the Arc-sized outer frame");
    NSRect small = NSMakeRect(-900,-400,720,500), fitted = DPBrowseFrame(NSMakeRect(-2000,0,1600,1200),small);
    NSCAssert(NSContainsRect(small,fitted) && NSWidth(fitted) < 720 && NSHeight(fitted) < 500, @"browser fits smaller secondary displays");
    NSCAssert(NSWidth(DPBrowseLauncherFrame(NSMakeRect(0,0,1920,1080),326)) == 490, @"global quick search keeps its compact width");
    NSURL *url = [NSURL URLWithString:@"https://www.chrome.example/path?q=one"];
    DPBrowseWindow *owner = DPBrowseOpen(url,source,NSZeroRect);
    NSCAssert(owner && owner.window.toolbarStyle == NSWindowToolbarStyleUnifiedCompact
        && owner.window.titleVisibility == NSWindowTitleHidden, @"browser has one native compact unified toolbar");
    NSCAssert([owner.window standardWindowButton:NSWindowCloseButton] && [owner.window standardWindowButton:NSWindowMiniaturizeButton], @"traffic lights remain native");
    [owner.window.contentView layoutSubtreeIfNeeded];
    NSCAssert(owner.window.contentView.subviews.count == 1 && owner.host.superview == owner.window.contentView
        && NSEqualRects(owner.host.frame,owner.window.contentView.bounds), @"web contents directly fill the area below the toolbar");
    DPMiniBrowserAddressPill *pill = (id)owner.addressPill;
    DPMiniBrowserOpenControl *open = (id)owner.openControl;
    NSCAssert(pill && open && owner.address.hidden && !owner.address.superview
        && [owner.address.stringValue isEqual:url.absoluteString], @"full URL stays in the model while the toolbar presents a domain");
    [pill showURL:url loading:YES progress:0.62]; [pill layout]; [open layout];
    NSCAssert([pill.domain.stringValue isEqual:@"chrome.example"] && !pill.progressView.hidden
        && fabs(pill.progressView.progress-0.62) < 0.001 && NSHeight(pill.bounds) == 30, @"domain and native load progress share the 30-point pill");
    NSCAssert(pill.domain.alignment == NSTextAlignmentCenter && NSContainsRect(pill.bounds,pill.linkButton.frame)
        && pill.editButton.action == @selector(editAddress:) && pill.linkButton.action == @selector(copyLink:), @"centered address and copy actions fit without touching the clipboard in tests");
    [pill showURL:url loading:NO progress:1];
    NSCAssert(pill.progressView.hidden && [[owner browserURLString] isEqual:url.absoluteString], @"copy uses the full URL and finished loading removes progress");
    [(id)owner.contents setValue:url forKey:@"url"];
    [owner prepareNavigationToURL:[NSURL URLWithString:@"https://cancelled.example/"]]; [owner reload:nil];
    NSCAssert(!owner.pendingURL && [owner.address.stringValue isEqual:url.absoluteString], @"navigation commands replace an uncommitted address draft");
    NSCAssert(open.primary.action == @selector(promote:) && open.arrow.action == @selector(showOpenDestinations:), @"split control has independent promotion and destination actions");
    NSWindow *target = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,600,400) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    target.releasedWhenClosed = NO; target.title = @"Work window"; target.accessibilityIdentifier = @"bigBrowserWindow-mini-chrome";
    DPBrowseSource *same = DPChromeDestination(source,target,YES,YES);
    DPBrowseSource *other = DPChromeDestination(source,target,NO,YES);
    NSCAssert([owner canPromoteToSource:same] && ![owner canPromoteToSource:other], @"same-profile windows can adopt without permitting a cross-profile transfer");
    DPTestMiniBrowserProfiles(owner, same);
    NSWindow *auxiliary = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,300,200) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    auxiliary.releasedWhenClosed = NO; auxiliary.accessibilityIdentifier = @"DiaTweaks.auxiliary";
    DPBrowseSource *nonBrowser = DPChromeDestination(source,auxiliary,YES,YES);
    NSArray *choices = DPBrowseMiniSourcesForProfile(owner,@[source,same,same,other,nonBrowser]);
    NSCAssert(choices.count == 2 && choices[0] == source && choices[1] == same, @"destination list preserves original default, removes duplicates and excludes other profiles and auxiliary windows");
    DPMiniBrowserDestinations *picker = [DPMiniBrowserDestinations new]; picker.owner = owner; picker.sources = choices;
    [picker loadView]; picker.search.stringValue = @"wOrK"; [picker filter:nil];
    NSCAssert(picker.filtered.count == 1 && picker.filtered.firstObject == same, @"window chooser searches case-insensitively");
    picker.search.stringValue = @"no matching window"; [picker filter:nil];
    NSCAssert(!picker.filtered.count && picker.table.selectedRow == -1, @"empty destination search leaves no selectable stale row");
    id<DPBrowseContents> page = owner.contents;
    picker.search.stringValue = @"work"; [picker filter:nil];
    [NSApp sendAction:picker.table.action to:picker.table.target from:picker.table];
    NSCAssert(owner.transferred && owner.closing && page.nativeView.window == target && !DPBrowseIsPromoting(), @"same-profile promotion moves the live contents and restores the synchronous adoption guard");
    [page close]; [target close]; [auxiliary close];
    owner = DPBrowseOpen(url,source,NSZeroRect); page = owner.contents;
    NSWindow *reject = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,600,400) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    reject.releasedWhenClosed = NO; reject.accessibilityIdentifier = @"bigBrowserWindow-mini-reject";
    DPBrowseSource *rejected = DPChromeDestination(source,reject,YES,NO);
    [owner promoteToSource:rejected];
    NSCAssert(owner.promoting, @"asynchronous promotion blocks edits and duplicate submissions");
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.8]];
    NSCAssert(!owner.promoting && !owner.transferred && owner.contents == page && page.nativeView.superview == owner.host,
        @"rejected handoff returns the original live page to Mini");
    [reject close]; NSCAssert(![owner canPromoteToSource:rejected], @"closed destination is rejected before detaching Mini");
    [owner close]; source.window.accessibilityIdentifier = sourceIdentifier; [source.window makeKeyAndOrderFront:nil];
}
