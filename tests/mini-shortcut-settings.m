#import "mini-shortcuts.h"

static NSEvent *DPShortcutEvent(NSWindow *window, NSEventType type, UInt16 code, NSEventModifierFlags modifiers, NSString *characters) {
    return [NSEvent keyEventWithType:type location:NSZeroPoint modifierFlags:modifiers timestamp:0 windowNumber:window.windowNumber
        context:nil characters:characters charactersIgnoringModifiers:characters isARepeat:NO keyCode:code];
}

void DPTestMiniShortcutSettings(void) {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,600,200) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = NO;
    DPFixtureShortcutPage *page = [objc_getClass("DPPageView") new]; page.orientation = NSUserInterfaceLayoutOrientationVertical;
    NSSwitch *mini = [NSSwitch new]; mini.accessibilityLabel = @"Dia Mini"; [page addArrangedSubview:mini];
    [page sync]; [page sync];
    NSCAssert(page.arrangedSubviews.count == 2, @"the Mini page gains one shortcut row even after repeated sync");
    window.contentView = page; [window makeKeyAndOrderFront:nil];
    DPMiniShortcutRecorder *recorder = (id)DPFindView(page, ^BOOL(NSView *v) { return [v isKindOfClass:DPMiniShortcutRecorder.class]; });
    NSCAssert(recorder && [recorder.title isEqual:@"⌥⌘N"], @"the settings recorder shows the current shortcut");
    NSEventModifierFlags flags = NSEventModifierFlagCommand | NSEventModifierFlagOption;
    [recorder startRecording];
    NSCAssert(recorder.recording && DPBrowseHotkeyPaused() && !DPBrowseHotkeyRegistered() && !DPNewMiniItem.keyEquivalent.length,
        @"recording suspends the global and menu binding");
    [recorder consumeEvent:DPShortcutEvent(window,NSEventTypeKeyDown,kVK_ANSI_M,flags,@"m")];
    NSCAssert([DPMiniShortcut.current sameKey:DPMiniShortcut.defaultShortcut], @"the key is not registered while it is still held");
    [recorder consumeEvent:DPShortcutEvent(window,NSEventTypeKeyUp,kVK_ANSI_M,flags,@"m")];
    NSCAssert(!recorder.recording && !DPBrowseHotkeyPaused() && DPBrowseHotkeyRegistered() && [recorder.title isEqual:@"⌥⌘M"],
        @"release saves the new chord without opening Mini");
    NSCAssert(!DPCurrentMiniLauncher, @"recording does not launch Mini");

    [recorder startRecording];
    [recorder consumeEvent:DPShortcutEvent(window,NSEventTypeKeyDown,kVK_ANSI_N,0,@"n")];
    NSCAssert([recorder.message containsString:@"Include"], @"invalid typing shows a useful error");
    [recorder consumeEvent:DPShortcutEvent(window,NSEventTypeKeyDown,kVK_Escape,0,@"\x1b")];
    NSCAssert(!recorder.recording && [recorder.title isEqual:@"⌥⌘M"] && DPBrowseHotkeyRegistered(), @"Escape restores the previous working shortcut");

    [recorder startRecording]; DPFixtureHotkeyStatus = eventHotKeyExistsErr;
    [recorder consumeEvent:DPShortcutEvent(window,NSEventTypeKeyDown,kVK_ANSI_K,flags,@"k")];
    [recorder consumeEvent:DPShortcutEvent(window,NSEventTypeKeyUp,kVK_ANSI_K,flags,@"k")];
    NSCAssert(recorder.recording && [recorder.message containsString:@"already in use"] && DPMiniShortcut.current.keyCode == kVK_ANSI_M,
        @"a registration conflict stays editable without saving the failed chord");
    DPFixtureHotkeyStatus = noErr; [recorder stopRecording];
    NSCAssert(!recorder.message.length && DPBrowseHotkeyRegistered(), @"canceling a conflict clears its message and restores the working binding");
    [recorder startRecording];
    [NSNotificationCenter.defaultCenter postNotificationName:NSWindowDidResignKeyNotification object:window];
    NSCAssert(!recorder.recording && !recorder.monitor && DPBrowseHotkeyRegistered(), @"focus loss cancels recording and removes the key monitor");
    [recorder startRecording]; [recorder removeFromSuperview];
    NSCAssert(!recorder.recording && !DPBrowseHotkeyPaused(), @"leaving the settings page restores the binding");
    [recorder resetShortcut:nil];
    NSCAssert([recorder.title isEqual:@"⌥⌘N"] && ![DPMiniShortcutDefaults() objectForKey:@"diaMiniShortcut"], @"Reset returns to Option-Command-N");
    [window close];

    DPFixtureShortcutPage *other = [objc_getClass("DPPageView") new];
    NSSwitch *peek = [NSSwitch new]; peek.accessibilityLabel = @"Peek"; [other addArrangedSubview:peek]; [other sync];
    NSCAssert(other.arrangedSubviews.count == 1, @"other patches do not gain Mini's control");
}
