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
    NSCAssert(owner && !owner.window.toolbar && owner.window.titlebarAppearsTransparent
        && (owner.window.styleMask & NSWindowStyleMaskFullSizeContentView)
        && owner.window.titleVisibility == NSWindowTitleHidden, @"the custom full-size titlebar replaces the automatic toolbar");
    NSCAssert([owner.window standardWindowButton:NSWindowCloseButton] && [owner.window standardWindowButton:NSWindowMiniaturizeButton], @"traffic lights remain native");
    [owner.window.contentView layoutSubtreeIfNeeded];
    NSCAssert(owner.window.contentView.subviews.count == 2 && owner.host.superview == owner.window.contentView
        && NSHeight(owner.host.frame) == NSHeight(owner.window.contentView.bounds) - 48
        && NSHeight(owner.browserHeader.frame) == 48, @"the page fills the body below an exact 48-point header");
    [owner.browserHeader layoutSubtreeIfNeeded];
    NSCAssert(owner.addressPill.frame.origin.x == 83 && owner.addressPill.frame.origin.y == 8
        && NSWidth(owner.openControl.frame) == owner.openControl.intrinsicContentSize.width && NSMaxX(owner.openControl.frame) == NSWidth(owner.browserHeader.bounds)-8
        && NSMinX(owner.openControl.frame)-NSMaxX(owner.addressPill.frame) == 8,
        @"the address, eight-point gaps and split control match the measured Arc header");
    NSVisualEffectView *header = (id)owner.browserHeader;
    NSCAssert(header.blendingMode == NSVisualEffectBlendingModeBehindWindow && !owner.window.opaque
        && CGColorGetAlpha(((DPMiniBrowserHeader *)header).tint.layer.backgroundColor) < 1, @"the header uses actual behind-window vibrancy and a translucent tint");
    DPMiniBrowserAddressPill *pill = (id)owner.addressPill;
    DPMiniBrowserOpenControl *open = (id)owner.openControl;
    NSCAssert(pill && open && owner.address.hidden && !owner.address.superview
        && [owner.address.stringValue isEqual:url.absoluteString], @"full URL stays in the model while the toolbar presents a domain");
    [pill showURL:url loading:YES progress:0.62]; [pill layout]; [open layout];
    NSCAssert([pill.domain.stringValue isEqual:@"chrome.example"] && !pill.progressView.hidden
        && fabs(pill.progressView.progress-0.62) < 0.001 && NSHeight(pill.bounds) == 30, @"domain and native load progress share the 30-point pill");
    NSCAssert(pill.domain.alignment == NSTextAlignmentCenter && NSContainsRect(pill.bounds,pill.linkButton.frame)
        && NSContainsRect(pill.bounds,pill.extensionButton.frame) && !NSIntersectsRect(pill.linkButton.frame,pill.extensionButton.frame)
        && fabs(NSMidY(pill.domain.frame)-NSMidY(pill.bounds)) < 0.5 && CGColorGetAlpha(pill.layer.backgroundColor) < 1
        && pill.editButton.action == @selector(editAddress:) && pill.linkButton.action == @selector(copyLink:), @"centered address and copy actions fit without touching the clipboard in tests");
    [pill showURL:url loading:NO progress:1];
    NSCAssert(pill.progressView.hidden && [[owner browserURLString] isEqual:url.absoluteString], @"copy uses the full URL and finished loading removes progress");
    [(id)owner.contents setValue:url forKey:@"url"];
    [owner prepareNavigationToURL:[NSURL URLWithString:@"https://cancelled.example/"]]; [owner reload:nil];
    NSCAssert(!owner.pendingURL && [owner.address.stringValue isEqual:url.absoluteString], @"navigation commands replace an uncommitted address draft");
    NSCAssert(open.primary.action == @selector(promote:) && open.arrow.action == @selector(showOpenDestinations:), @"split control has independent promotion and destination actions");
    [open setDestinationTitle:@"Personal"]; [owner.browserHeader layout]; [open layout];
    NSCAssert([open.titleLabel.stringValue isEqual:@"Open in Personal"] && NSWidth(open.frame) >= open.intrinsicContentSize.width
        && NSContainsRect(open.bounds,open.shortcutLabel.frame) && !NSIntersectsRect(open.titleLabel.frame,open.shortcutLabel.frame)
        && open.shortcutLabel.layer.cornerRadius > 0, @"native destination titles fit beside a separate rounded shortcut keycap");
    [open setDestinationTitle:@"Dia"]; [owner.browserHeader layout];
    NSWindow *target = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,600,400) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    target.releasedWhenClosed = NO; target.title = @"Work window"; target.accessibilityIdentifier = @"bigBrowserWindow-mini-chrome";
    DPBrowseSource *same = DPChromeDestination(source,target,YES,YES);
    DPBrowseSource *other = DPChromeDestination(source,target,NO,YES);
    NSCAssert([owner canPromoteToSource:same] && ![owner canPromoteToSource:other], @"same-profile windows can adopt without permitting a cross-profile transfer");
    DPTestMiniBrowserProfiles(owner, same);
    NSMenu *nativeMenu = [NSMenu new]; nativeMenu.autoenablesItems = NO;
    NSMenuItem *move = [[NSMenuItem alloc] initWithTitle:@"Move to Space" action:nil keyEquivalent:@""];
    move.submenu = [NSMenu new]; move.submenu.autoenablesItems = NO; [nativeMenu addItem:move];
    NSMenuItem *work = [[NSMenuItem alloc] initWithTitle:@"Work" action:@selector(promote:) keyEquivalent:@""];
    work.target = owner; work.identifier = @"space:work"; [move.submenu addItem:work];
    NSMenuItem *personal = [[NSMenuItem alloc] initWithTitle:@"Personal" action:@selector(promote:) keyEquivalent:@""];
    personal.target = owner; personal.state = NSControlStateValueOn; personal.enabled = NO;
    personal.identifier = @"space:personal"; [move.submenu addItem:personal];
    DPMiniBrowserDestinations *picker = [DPMiniBrowserDestinations new]; picker.owner = owner;
    picker.catalog = DPBrowseDiscoverNativeDestinations(nativeMenu, NO);
    [picker loadView];
    NSCAssert(NSWidth(picker.view.bounds) == 245 && picker.table.rowHeight == 46
        && fabs(NSMidY(picker.search.frame)-22) < 0.5 && picker.search.usesSingleLineMode
        && picker.table.selectedRow == 1 && [picker tableView:picker.table shouldSelectRow:1],
        @"the measured picker keeps the current destination selectable even when its native move action is disabled");
    picker.search.stringValue = @"wOrK"; [picker filter:nil];
    NSCAssert(picker.filtered.count == 1 && [picker.filtered.firstObject.nativeIdentifier isEqual:@"space:work"]
        && [picker.search.placeholderString isEqual:@"Search Spaces…"], @"native Space metadata, rather than window titles, supplies the searchable picker");
    picker.search.stringValue = @"no matching destination"; [picker filter:nil];
    NSCAssert(!picker.filtered.count && picker.table.selectedRow == -1, @"empty destination search leaves no selectable stale row");
    id<DPBrowseContents> page = owner.contents;
    [picker choose:nil];
    NSCAssert(owner.contents == page && !owner.promoting && !owner.transferred, @"an empty native destination search never promotes the page");
    DPMiniBrowserDestinations *unavailable = [DPMiniBrowserDestinations new]; unavailable.owner = owner; [unavailable loadView];
    NSCAssert(!unavailable.filtered.count && unavailable.table.selectedRow == -1 && !unavailable.status.hidden
        && [unavailable.status.stringValue isEqual:@"No destinations available"], @"unavailable native catalogs have an honest empty state");
    owner.promoting = YES; page.hasFocus = YES;
    [owner windowDidResignKey:[NSNotification notificationWithName:NSWindowDidResignKeyNotification object:owner.window]];
    NSCAssert(page.hasFocus, @"Mini relinquishes focus ownership while the regular browser adopts the page");
    owner.promoting = NO;
    [owner promoteToSource:same];
    NSCAssert(owner.transferred && owner.closing && page.nativeView.window == target && !DPBrowseIsPromoting(), @"same-profile promotion moves the live contents and restores the synchronous adoption guard");
    [page close]; [target close];
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
