#import "Patches/CommandBar/CommandBar.h"
#import "mini-shortcuts.h"

static BOOL DPCommandFailWrite;
static BOOL DPCommandSynchronize(NSUserDefaults *self, SEL _cmd) {
    if (DPCommandFailWrite && self == DPMiniShortcutDefaults()) { DPCommandFailWrite = NO; return NO; }
    return DPCallOriginal(DPCommandSynchronize, self);
}

void DPTestCommandBarShortcuts(void) {
    NSUserDefaults *defaults = DPMiniShortcutDefaults();
    id saved = [defaults objectForKey:@"commandBarShortcut"]; BOOL enabled = DPCommandBar.on;
    [defaults removeObjectForKey:@"commandBarShortcut"];
    DPCommandBarInstallKeyboard();
    NSMenu *file = [NSApp.mainMenu itemWithTitle:@"File"].submenu;
    NSMenuItem *nativeK = [[NSMenuItem alloc] initWithTitle:@"Native K" action:nil keyEquivalent:@"k"];
    NSMenuItem *nativeT = [[NSMenuItem alloc] initWithTitle:@"New Tab" action:nil keyEquivalent:@"t"];
    NSMenuItem *reserved = [[NSMenuItem alloc] initWithTitle:@"Reserved Action" action:nil keyEquivalent:@"r"];
    for (NSMenuItem *item in @[nativeK, nativeT, reserved]) { item.keyEquivalentModifierMask = NSEventModifierFlagCommand; [file addItem:item]; }
    NSUInteger registrations = DPFixtureRegistrations;
    DPCommandBar.on = YES; DPCommandBarUpdateBinding();
    NSCAssert([DPCommandBarShortcut.current.label isEqual:@"⌘K"] && !nativeK.keyEquivalent.length
        && [nativeT.keyEquivalent isEqual:@"t"] && [DPCommandBarItem.keyEquivalent isEqual:@"k"], @"Command-K is the default and takes over its native binding");
    NSString *error = nil;
    DPMiniShortcut *cmdT = [[DPMiniShortcut alloc] initWithCode:kVK_ANSI_T modifiers:NSEventModifierFlagCommand characters:@"t"];
    NSCAssert(DPCommandBarSaveShortcut(cmdT, NO, &error) && [nativeK.keyEquivalent isEqual:@"k"]
        && !nativeT.keyEquivalent.length && [DPCommandBarItem.keyEquivalent isEqual:@"t"], @"Command-T can replace native New Tab and restores the old binding");
    DPCommandBar.on = NO; DPCommandBarUpdateBinding();
    NSCAssert([nativeT.keyEquivalent isEqual:@"t"] && [nativeK.keyEquivalent isEqual:@"k"] && DPCommandBarItem.hidden,
        @"disabling restores native shortcuts");
    DPCommandBar.on = YES;
    DPMiniShortcut *custom = [[DPMiniShortcut alloc] initWithCode:kVK_ANSI_M modifiers:NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption characters:@"m"];
    NSCAssert(DPCommandBarSaveShortcut(custom, NO, &error) && [DPCommandBarShortcut.current sameKey:custom], @"custom shortcuts persist independently");
    NSUserDefaults *fresh = [[NSUserDefaults alloc] initWithSuiteName:@(getenv("DIATWEAKS_DOMAIN"))];
    NSCAssert([[fresh dictionaryForKey:@"commandBarShortcut"] isEqual:custom.dictionary], @"a fresh preferences instance reads the saved binding");
    NSCAssert(!DPCommandBarSaveShortcut(DPMiniShortcut.current, NO, &error) && [error containsString:@"Mini"], @"Mini’s binding is reserved even while it is paused");
    DPMiniShortcut *cmdR = [[DPMiniShortcut alloc] initWithCode:kVK_ANSI_R modifiers:NSEventModifierFlagCommand characters:@"r"];
    NSCAssert(!DPCommandBarSaveShortcut(cmdR, NO, &error) && [error containsString:reserved.title], @"other native shortcuts are rejected");
    DPHookClass(NSUserDefaults.class, @selector(synchronize), (IMP)DPCommandSynchronize);
    DPCommandFailWrite = YES;
    NSCAssert(!DPCommandBarSaveShortcut(cmdT, NO, &error) && [error containsString:@"save"]
        && [DPCommandBarShortcut.current sameKey:custom] && [DPCommandBarItem.keyEquivalent isEqual:@"m"], @"failed writes preserve the working preference and menu binding");
    NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:custom.modifiers timestamp:0
        windowNumber:0 context:nil characters:@"m" charactersIgnoringModifiers:@"m" isARepeat:YES keyCode:custom.keyCode];
    DPCommandBarPauseShortcut(YES); NSCAssert(!DPCommandBarHandleEvent(event) && !DPCommandBarItem.keyEquivalent.length, @"recording pauses local interception");
    DPCommandBarPauseShortcut(NO); NSCAssert(DPCommandBarHandleEvent(event), @"the local binding resumes without creating another global hotkey");
    NSCAssert(registrations == DPFixtureRegistrations, @"Command Bar never registers a global hotkey");
    DPBrowsePauseHotkey(YES); NSCAssert(!DPCommandBarHandleEvent(event), @"the Mini recorder also suspends Command Bar"); DPBrowsePauseHotkey(NO);
    NSCAssert(DPCommandBarMiniShortcutConflict(custom) && !DPCommandBarMiniShortcutConflict(DPMiniShortcut.current), @"Mini can detect Command Bar collisions independently of cleared menu equivalents");
    NSCAssert(DPCommandBarSaveShortcut(DPCommandBarShortcut.defaultShortcut, YES, &error) && ![defaults objectForKey:@"commandBarShortcut"], @"Reset restores Command-K");
    DPCommandBar.on = NO; DPCommandBarUpdateBinding();
    for (NSMenuItem *item in @[nativeK, nativeT, reserved]) [file removeItem:item];
    if (saved) [defaults setObject:saved forKey:@"commandBarShortcut"]; else [defaults removeObjectForKey:@"commandBarShortcut"];
    [defaults synchronize]; DPCommandBar.on = enabled; DPCommandBarUpdateBinding();
}
