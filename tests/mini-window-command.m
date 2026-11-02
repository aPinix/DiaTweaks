#import "Patches/DiaMini/Browse/WindowCommand.h"
#import "Patches/DiaMini/Search/Provider.h"
#import "Patches/CommandBar/CommandBar.h"
#import "Patches/DiaMini/Browse/BrowserToolbar.h"

static NSEvent *DPMiniCommandKey(NSWindow *window, NSString *key, unsigned short code, NSEventModifierFlags flags) {
    return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:flags timestamp:0
        windowNumber:window.windowNumber context:nil characters:key charactersIgnoringModifiers:key isARepeat:NO keyCode:code];
}
static DPMiniWindowCommand *DPMiniCommandPalette(DPBrowseWindow *owner, BOOL prefill) {
    DPBrowseEditMini(owner, prefill);
    NSCAssert([DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class], @"Mini has its own shared-input palette");
    return (id)DPCurrentMiniLauncher;
}
static void DPMiniCommandClose(DPMiniLauncher *launcher) { launcher.restorePrevious = NO; [launcher close]; }

static void DPMiniCommandChooser(DPBrowseWindow *owner) {
    [owner.window makeKeyAndOrderFront:nil];
    [owner showOpenDestinations:owner.openControl];
    DPMiniBrowserDestinationPicker *chooser = owner.destinationPopover;
    NSWindow *popup = chooser.contentViewController.view.window;
    NSCAssert(chooser.shown && popup && DPBrowseMiniForWindow(popup) == owner, @"destination popup keys retain their Mini owner");
    NSCAssert(DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(popup, @"t", kVK_ANSI_T, NSEventModifierFlagCommand))
        && !chooser.shown && [DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class]
        && ((DPMiniWindowCommand *)DPCurrentMiniLauncher).miniOwner == owner,
        @"new search from the destination picker remains inside Mini");
    DPMiniCommandClose(DPCurrentMiniLauncher);
}

static void DPMiniCommandInput(DPBrowseWindow *owner) {
    NSURL *current = [NSURL URLWithString:@"https://example.com/docs?q=arc#top"];
    [(id)owner.contents setValue:current forKey:@"url"]; [owner prepareNavigationToURL:current]; [owner updatePage];
    DPMiniWindowCommand *palette = DPMiniCommandPalette(owner, YES);
    NSTextView *editor = (id)palette.search.currentEditor;
    NSCAssert([palette.search.stringValue isEqual:current.absoluteString] && [editor isKindOfClass:NSTextView.class]
        && NSEqualRanges(editor.selectedRange, NSMakeRange(0, current.absoluteString.length)), @"address editing selects the complete current URL");
    NSCAssert(palette.source == owner.source && palette.window.parentWindow == owner.window
        && DPBrowseMiniForWindow(palette.window) == owner && DPBrowseMiniForWindow(owner.window) == owner,
        @"the palette belongs to the live Mini without changing its source window");
    NSCAssert([palette.window.identifier isEqual:@"DiaTweaks.MiniCommandBar"]
        && [palette.search.accessibilityIdentifier isEqual:@"DiaMiniCommandSearchField"], @"owned palette accessibility differs from the global launcher");
    DPMiniWindowCommand *same = DPMiniCommandPalette(owner, NO);
    NSCAssert(same == palette && !palette.search.stringValue.length && !palette.typedQuery.length,
        @"the empty command route reuses the palette and clears an address draft");
    DPSiteSearchProvider *provider = [DPSiteSearchProvider new]; provider.name = @"YouTube"; provider.keyword = @"youtube.com";
    provider.templateURL = @"https://youtube.com/results?search_query={searchTerms}"; palette.siteProvider = provider;
    [palette control:palette.search textView:(id)palette.search.currentEditor doCommandBySelector:@selector(cancelOperation:)];
    NSCAssert(!palette.siteProvider && !palette.search.stringValue.length && palette.window.visible, @"first scoped Escape clears the scope");
    NSCAssert(!DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(palette.window, @"\x1b", 53, 0)), @"palette Escape belongs to its shared field handler");
    [palette control:palette.search textView:(id)palette.search.currentEditor doCommandBySelector:@selector(cancelOperation:)];
    NSCAssert(!palette.window.visible && owner.window.visible && owner.contents, @"second Escape dismisses only the palette");
    palette = DPMiniCommandPalette(owner, NO);
    id contents = owner.contents; DPBrowseSource *source = owner.source; NSRunningApplication *previous = owner.returnApplication;
    NSUInteger count = DPBrowseWindows.count; NSURL *target = [NSURL URLWithString:@"https://same-mini.example/path?query=1"];
    palette.search.stringValue = target.absoluteString; [palette userInputDidChange]; [palette setResults:@[]]; [palette choose:nil];
    NSCAssert(!palette.window.visible && owner.contents == contents && owner.source == source && owner.returnApplication == previous
        && DPBrowseWindows.count == count && [[contents valueForKeyPath:@"navigationController.loaded"] isEqual:target]
        && [contents nativeView].window == owner.window, @"Return navigates the same live Mini with its profile and return application intact");
    owner.promoting = YES;
    DPBrowseEditMini(owner, NO);
    NSCAssert(!DPCurrentMiniLauncher && !DPBrowseLoadMini(owner, current), @"a promotion cannot race another palette navigation");
    NSCAssert(DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(owner.window, @"w", kVK_ANSI_W, NSEventModifierFlagCommand))
        && DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(owner.window, @"l", kVK_ANSI_L, NSEventModifierFlagCommand))
        && owner.window.visible && owner.contents == contents && !DPCurrentMiniLauncher,
        @"busy Mini commands are consumed without reaching main tabs or interrupting native adoption");
    owner.promoting = NO;
    NSCAssert(!DPBrowseLoadMini(owner, [NSURL URLWithString:@"javascript:alert(1)"]), @"in-place navigation only accepts safe browser URLs");
    DPBrowseSource *detached = [DPBrowseSource new]; detached.browser = source.browser;
    detached.contents = source.contents; detached.delegate = source.delegate; detached.browserDelegate = source.browserDelegate;
    owner.source = detached; palette = DPMiniCommandPalette(owner, NO);
    NSCAssert(palette.launcherEnabled && palette.source.browser == source.browser && DPBrowseLoadMini(owner, current)
        && owner.contents == contents, @"a live Mini still edits and navigates in its profile after the original window is gone");
    DPMiniCommandClose(palette); owner.source = source;
}

static void DPMiniCommandLifecycle(DPBrowseWindow *owner) {
    DPMiniWindowCommand *palette = DPMiniCommandPalette(owner, NO);
    [owner.window.contentView layoutSubtreeIfNeeded];
    NSView *scrim = palette.miniScrim; NSWindow *shadow = palette.shadowWindow;
    NSCAssert(scrim.superview == owner.host.superview && NSEqualRects(scrim.frame, owner.host.frame), @"only the browser body is dimmed");
    NSRect content = [owner.window convertRectToScreen:[owner.window.contentView convertRect:owner.window.contentView.bounds toView:nil]];
    NSCAssert(NSWidth(palette.window.frame) <= 500 && fabs(NSMidX(palette.window.frame) - NSMidX(content)) < 1,
        @"the Mini palette has the native centered width");
    [owner.window setContentSize:NSMakeSize(620, 420)];
    [NSNotificationCenter.defaultCenter postNotificationName:NSWindowDidResizeNotification object:owner.window];
    NSRect body = [owner.window convertRectToScreen:[owner.host convertRect:owner.host.bounds toView:nil]];
    NSCAssert(NSContainsRect(body, palette.window.frame) && NSWidth(palette.window.frame) <= 500, @"resizing keeps the palette inside the owner's body");
    NSEvent *outside = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown location:NSZeroPoint modifierFlags:0
        timestamp:0 windowNumber:owner.window.windowNumber context:nil eventNumber:1 clickCount:1 pressure:1];
    [scrim mouseDown:outside];
    NSCAssert(!palette.window.visible && !shadow.visible && !scrim.superview && !palette.window.parentWindow
        && !palette.outsideMouseMonitor && owner.window.visible, @"a consumed body click removes the palette, shadow and scrim without closing the page");
    palette = DPMiniCommandPalette(owner, NO); DPBrowseSource *source = palette.source;
    DPBrowseShowLauncher(); DPMiniLauncher *global = DPCurrentMiniLauncher;
    NSCAssert(global && ![global isKindOfClass:DPMiniWindowCommand.class] && global.source == source && !global.window.parentWindow
        && !palette.window.visible && !palette.miniScrim && [global.window.identifier isEqual:@"DiaTweaks.MiniLauncher"],
        @"the global shortcut replaces the owned palette with a separate launcher in the same profile");
    DPMiniCommandClose(global); palette = DPMiniCommandPalette(owner, NO); scrim = palette.miniScrim; shadow = palette.shadowWindow;
    [owner close];
    NSCAssert(!palette.window.visible && !shadow.visible && !scrim.superview && !palette.window.parentWindow && !DPCurrentMiniLauncher
        && !palette.miniResizeObserver && !palette.miniCloseObserver, @"closing the owner removes every owned palette resource");
}

void DPTestMiniWindowCommand(DPBrowseSource *source) {
    NSCAssert(!DPCurrentMiniLauncher && !DPBrowseWindows.count, @"the Mini palette fixture starts without other palettes or previews");
    BOOL miniOn = DPDiaMini.on, commandOn = DPCommandBar.on; NSWindow *sourceWindow = source.window;
    DPDiaMini.on = YES; DPBrowseApply(&DPDiaMini); DPCommandBar.on = NO; DPCommandBar.apply(&DPCommandBar);
    DPBrowseWindow *owner = DPBrowseOpen([NSURL URLWithString:@"https://example.com/"], source, NSZeroRect);
    NSCAssert(owner && source.window == sourceWindow, @"opening Mini preserves the original source identity");
    NSEventModifierFlags command = NSEventModifierFlagCommand;
    NSCAssert(DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(owner.window, @"l", kVK_ANSI_L, command))
        && DPCurrentMiniLauncher.window.visible, @"Mini address editing works with Command Bar off");
    NSCAssert(!DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(owner.window, @"l", kVK_ANSI_L, command | NSEventModifierFlagOption)),
        @"modified address shortcuts keep their own meaning");
    DPMiniCommandClose(DPCurrentMiniLauncher); DPMiniCommandInput(owner); DPMiniCommandChooser(owner);
    DPCommandBar.on = YES; DPCommandBar.apply(&DPCommandBar);
    DPMiniShortcut *binding = DPCommandBarShortcut.current;
    NSCAssert(DPCommandBarHandleEvent(DPMiniCommandKey(owner.window, binding.characters, binding.keyCode, binding.modifiers))
        && [DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class], @"the configurable Command Bar chord routes by Mini event window");
    DPCommandBar.on = NO; DPCommandBar.apply(&DPCommandBar);
    NSCAssert(DPCurrentMiniLauncher.window.visible, @"disabling Command Bar leaves Mini-owned address editing available");
    for (NSString *key in @[@"l", @"o", @"r", @"[", @"]", @"w"]) {
        DPMiniShortcut *shortcut = [[DPMiniShortcut alloc] initWithCode:0 modifiers:command characters:key];
        NSCAssert(DPBrowseReservedMiniShortcut(shortcut) && DPCommandBarShortcutConflict(shortcut, [NSMenu new]),
            @"intrinsic Mini chords cannot be assigned to either configurable palette");
    }
    NSCAssert(!DPBrowseReservedMiniShortcut([[DPMiniShortcut alloc] initWithCode:kVK_ANSI_T modifiers:command characters:@"t"]),
        @"Command-T remains available as a configurable Command Bar shortcut");
    DPMiniCommandClose(DPCurrentMiniLauncher); DPMiniCommandLifecycle(owner);
    owner = DPBrowseOpen([NSURL URLWithString:@"https://example.com/"], source, NSZeroRect);
    NSCAssert(DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(owner.window, @"t", kVK_ANSI_T, command))
        && DPCurrentMiniLauncher.window.visible && !DPCurrentMiniLauncher.search.stringValue.length,
        @"Mini's New Tab chord opens an empty palette even with Command Bar disabled");
    NSCAssert(DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(DPCurrentMiniLauncher.window, @"w", kVK_ANSI_W, command))
        && !DPCurrentMiniLauncher && owner.window.visible, @"Close Window first dismisses an owned palette without touching the page");
    NSCAssert(DPBrowseHandleMiniKeyEvent(DPMiniCommandKey(owner.window, @"w", kVK_ANSI_W, command))
        && !owner.window.visible && !DPBrowseWindows.count, @"Close Window in Mini closes the browser without reaching Dia's tab action");
    owner = DPBrowseOpen([NSURL URLWithString:@"https://example.com/"], source, NSZeroRect);
    DPMiniWindowCommand *palette = DPMiniCommandPalette(owner, NO); NSView *scrim = palette.miniScrim;
    DPDiaMini.on = NO; DPBrowseApply(&DPDiaMini);
    NSCAssert(!owner.window.visible && !palette.window.visible && !scrim.superview && !DPBrowseWindows.count
        && !DPCurrentMiniLauncher, @"disabling Mini closes its page and owned palette together");
    NSCAssert(!DPBrowseLoadMini(owner, [NSURL URLWithString:@"https://example.net/"]), @"a closed Mini cannot be navigated");
    DPCommandBar.on = commandOn; DPCommandBar.apply(&DPCommandBar); DPDiaMini.on = miniOn; DPBrowseApply(&DPDiaMini);
    [sourceWindow makeKeyAndOrderFront:nil];
}
