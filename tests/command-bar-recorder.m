#import "Patches/CommandBar/CommandBar.h"
#import "Settings/Settings.h"

static NSEvent *DPCommandRecordEvent(NSWindow *window, NSEventType type, UInt16 code, NSString *characters) {
    return [NSEvent keyEventWithType:type location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:0
        windowNumber:window.windowNumber context:nil characters:characters charactersIgnoringModifiers:characters isARepeat:NO keyCode:code];
}

void DPTestCommandBarRecorder(void) {
    NSUserDefaults *defaults = DPMiniShortcutDefaults(); id saved = [defaults objectForKey:@"commandBarShortcut"];
    [defaults removeObjectForKey:@"commandBarShortcut"];
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,600,200) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = NO;
    DPCommandBarInstallSettings();
    DPPageView *page = [objc_getClass("DPPageView") new]; page.orientation = NSUserInterfaceLayoutOrientationVertical;
    NSSwitch *toggle = [NSSwitch new]; toggle.accessibilityLabel = @"Command Bar"; [page addArrangedSubview:toggle];
    [page sync]; [page sync];
    DPCommandBarRecorder *recorder = (id)DPFindView(page, ^BOOL(NSView *view) { return [view isKindOfClass:DPCommandBarRecorder.class]; });
    NSCAssert(recorder && page.arrangedSubviews.count == 2, @"the Command Bar settings page inserts one recorder row");
    window.contentView = page; [window makeKeyAndOrderFront:nil];
    NSCAssert([recorder.title isEqual:@"⌘K"] && [recorder.accessibilityLabel isEqual:@"Command Bar keyboard shortcut"], @"the recorder shows Command Bar’s own preference");
    [recorder startRecording];
    NSCAssert(recorder.recording && DPCommandBarShortcutPaused() && DPBrowseHotkeyPaused(), @"recording suspends both launchers");
    [recorder consumeEvent:DPCommandRecordEvent(window, NSEventTypeKeyDown, kVK_ANSI_T, @"t")];
    NSCAssert(recorder.pending && [DPCommandBarShortcut.current.label isEqual:@"⌘K"], @"capturing a key does not save before release");
    [recorder consumeEvent:DPCommandRecordEvent(window, NSEventTypeKeyUp, kVK_ANSI_T, @"t")];
    NSCAssert(!recorder.recording && !DPCommandBarShortcutPaused() && [DPCommandBarShortcut.current.label isEqual:@"⌘T"], @"release saves the Command Bar preference and resumes interception");
    [recorder resetShortcut:nil]; NSCAssert([recorder.title isEqual:@"⌘K"], @"Reset uses Command Bar’s default");
    [recorder startRecording]; [recorder removeFromSuperview];
    NSCAssert(!recorder.recording && !DPCommandBarShortcutPaused() && !DPBrowseHotkeyPaused(), @"leaving the page resumes both bindings");
    [window close];
    if (saved) [defaults setObject:saved forKey:@"commandBarShortcut"]; else [defaults removeObjectForKey:@"commandBarShortcut"];
    [defaults synchronize]; DPCommandBarUpdateBinding();
}
