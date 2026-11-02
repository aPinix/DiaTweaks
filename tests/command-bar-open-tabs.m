#import "Patches/CommandBar/OpenTabs.h"

NSDictionary *DPCommandSwitchFixture(id browser, NSWindow *window, NSString *url, NSString *title, NSInteger identifier);
id DPCommandSwitchSelected(NSDictionary *fixture);
BOOL DPCommandSwitchActivated(NSDictionary *fixture);
void DPCommandSwitchInitialized(NSDictionary *fixture, BOOL initialized);
void DPCommandSwitchCloseNotice(NSDictionary *fixture);
void DPCommandSwitchCleanup(NSDictionary *fixture);

static DPCommandTabSuggestion *DPSwitchRow(NSArray<DPCommandTabSuggestion *> *rows, NSDictionary *fixture) {
    for (DPCommandTabSuggestion *row in rows) if (row.contents == fixture[@"page"]) return row;
    return nil;
}
void DPTestCommandBarOpenTabs(DPBrowseSource *source) {
    DPCommandBarInstallTabLookup(); BOOL enabled = DPCommandBar.on; DPCommandBar.on = YES;
    NSString *url = @"https://switch-fixture.example/one";
    NSDictionary *first = DPCommandSwitchFixture(source.browser, source.window, url, @"Switch fixture Alpha", 101);
    NSDictionary *duplicate = DPCommandSwitchFixture(source.browser, source.window, url, @"Switch fixture Beta", 102);
    NSDictionary *second = DPCommandSwitchFixture(source.browser, source.window, @"https://switch-fixture.example/two", @"Another switch fixture", 103);
    NSWindow *otherWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,800,600) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    otherWindow.releasedWhenClosed = NO;
    NSDictionary *other = DPCommandSwitchFixture(source.browser, otherWindow, url, @"Switch fixture other window", 104);
    id otherBrowser = [objc_getClass(DPDiaBrowser) new];
    NSDictionary *foreign = DPCommandSwitchFixture(otherBrowser, source.window, url, @"Switch fixture other profile", 105);
    NSDictionary *preview = DPCommandSwitchFixture(source.browser, source.window, url, @"Switch fixture Mini", 106);
    NSDictionary *peek = DPCommandSwitchFixture(source.browser, source.window, url, @"Switch fixture Peek", 107);
    NSView *peekRoot = [[objc_getClass("DPPeekCard") alloc] initWithFrame:NSMakeRect(0,0,100,100)]; peekRoot.hidden = YES;
    [source.window.contentView addSubview:peekRoot]; [peekRoot addSubview:peek[@"host"]];
    NSDictionary *preloaded = DPCommandSwitchFixture(source.browser, source.window, url, @"Switch fixture preload", 108);
    [(id<DPBrowseContents>)preloaded[@"page"] setUIDelegate:nil];
    DPBrowseWindow *mini = [DPBrowseWindow new]; mini.source = source; mini.contents = preview[@"page"]; [DPBrowseWindows addObject:mini];
    NSArray *matches = DPCommandBarMatchingTabs(source, @"SWITCH-FIXTURE");
    DPCommandTabSuggestion *a = DPSwitchRow(matches, first), *b = DPSwitchRow(matches, duplicate);
    NSCAssert(matches.count == 3 && a && b && DPSwitchRow(matches, second) && [a.actionLabel isEqual:@"Switch to Tab"],
        @"matching includes duplicate tabs and excludes other windows, profiles, Mini, Peek and preloaded pages");
    NSCAssert(DPCommandBarMatchingTabs(source, @"fixture Alpha").count == 1, @"titles are searchable as well as URLs");
    NSUInteger before = DPBrowseKnownContents().count;
    NSCAssert(DPCommandBarActivateTab(b, source) && DPCommandSwitchSelected(duplicate) == duplicate[@"page"]
        && DPCommandSwitchActivated(duplicate) && !DPCommandSwitchSelected(first) && DPBrowseKnownContents().count == before
        && ![duplicate[@"page"] valueForKeyPath:@"navigationController.loaded"], @"switching targets the exact page without creating or loading another page");
    DPCommandBar.on = NO; NSCAssert(!DPCommandBarActivateTab(a, source), @"a disabled Command Bar cannot select a tab"); DPCommandBar.on = YES;
    [first[@"session"] setValue:@999 forKey:@"identifier"];
    NSCAssert(!DPCommandBarTabIsCurrent(a, source) && !DPCommandBarActivateTab(a, source), @"session changes invalidate an old result");
    [first[@"session"] setValue:@101 forKey:@"identifier"];
    [(id<DPBrowseContents>)first[@"page"] setUIDelegate:nil];
    NSCAssert(!DPCommandBarTabIsCurrent(a, source), @"a detached native delegate invalidates a stale result");
    [(id<DPBrowseContents>)first[@"page"] setUIDelegate:first[@"delegate"]];
    DPCommandSwitchInitialized(first, NO); NSCAssert(!DPCommandBarTabIsCurrent(a, source), @"uninitialized pages are not selectable"); DPCommandSwitchInitialized(first, YES);
    DPCommandSwitchCloseNotice(first);
    NSCAssert(!DPCommandBarTabIsCurrent(a, source) && !DPSwitchRow(DPCommandBarMatchingTabs(source, @"switch-fixture"), first),
        @"native close notifications invalidate retained page objects and remove their rows");
    DPBrowseSource *otherSource = [DPBrowseSource new]; otherSource.browser = source.browser; otherSource.window = otherWindow;
    otherSource.contents = other[@"page"]; otherSource.delegate = other[@"delegate"];
    DPCommandTabSuggestion *otherRow = DPSwitchRow(DPCommandBarMatchingTabs(otherSource, @"switch-fixture"), other);
    NSCAssert(otherRow && !DPCommandBarActivateTab(otherRow, source) && !DPCommandSwitchSelected(other), @"a snapshot cannot cross source windows");
    otherSource.browser = otherBrowser; otherSource.window = source.window; otherSource.contents = foreign[@"page"]; otherSource.delegate = foreign[@"delegate"];
    DPCommandTabSuggestion *foreignRow = DPSwitchRow(DPCommandBarMatchingTabs(otherSource, @"switch-fixture"), foreign);
    NSCAssert(foreignRow && !DPCommandBarActivateTab(foreignRow, source) && !DPCommandSwitchSelected(foreign), @"a snapshot cannot cross profile contexts");
    [DPBrowseWindows removeObject:mini];
    for (NSDictionary *fixture in @[first, duplicate, second, other, foreign, preview, peek, preloaded]) DPCommandSwitchCleanup(fixture);
    [peekRoot removeFromSuperview];
    [otherWindow close]; DPCommandBar.on = enabled; [source.window makeKeyAndOrderFront:nil];
}
