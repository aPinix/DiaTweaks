#import "mini-shortcuts.h"

static BOOL DPFailShortcutWrite;
static BOOL DPShortcutSynchronize(NSUserDefaults *self, SEL _cmd) {
    if (DPFailShortcutWrite && self == DPMiniShortcutDefaults()) { DPFailShortcutWrite = NO; return NO; }
    return DPCallOriginal(DPShortcutSynchronize, self);
}

static NSDictionary *DPReadShortcutInNewProcess(void) {
    NSTask *task = [NSTask new]; NSPipe *output = [NSPipe pipe];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/defaults"];
    task.arguments = @[@"export", @(getenv("DIATWEAKS_DOMAIN")), @"-"];
    task.standardOutput = output; task.standardError = NSFileHandle.fileHandleWithNullDevice;
    NSCAssert([task launchAndReturnError:NULL], @"launch a fresh preferences reader");
    NSData *data = [output.fileHandleForReading readDataToEndOfFile]; [task waitUntilExit];
    return [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL][@"diaMiniShortcut"];
}

void DPTestMiniShortcuts(void) {
    DPHookClass(NSUserDefaults.class,@selector(synchronize),(IMP)DPShortcutSynchronize);
    NSEventModifierFlags standard = NSEventModifierFlagOption | NSEventModifierFlagCommand;
    NSUserDefaults *defaults = DPMiniShortcutDefaults();
    NSCAssert([DPMiniShortcut.current sameKey:DPMiniShortcut.defaultShortcut] && DPMiniShortcut.current.modifiers == standard,
        @"default Mini shortcut is Option-Command-N without Control");
    DPBrowseApply(&DPDiaMini);
    NSCAssert(DPBrowseHotkeyRegistered() && DPFixtureHotkeyCode == kVK_ANSI_N && DPFixtureHotkeyModifiers == (optionKey | cmdKey)
        && DPFixtureHotkeyOptions == kEventHotKeyExclusive, @"the default is registered globally and exclusively");

    DPMiniShortcut *custom = [[DPMiniShortcut alloc] initWithCode:kVK_ANSI_M modifiers:standard | NSEventModifierFlagControl characters:@"m"];
    NSUInteger releases = DPFixtureUnregistrations;
    DPFixtureHotkeyStatus = eventHotKeyExistsErr; NSString *error = nil;
    NSCAssert(!DPMiniSaveShortcut(custom, NO, &error) && error.length && DPFixtureUnregistrations == releases
        && DPBrowseHotkeyRegistered() && [DPMiniShortcut.current sameKey:DPMiniShortcut.defaultShortcut], @"a rejected replacement preserves the working hotkey and preferences");
    DPFixtureHotkeyStatus = noErr;
    DPFailShortcutWrite = YES;
    NSCAssert(!DPMiniSaveShortcut(custom, NO, &error) && [error containsString:@"save"] && DPBrowseHotkeyRegistered()
        && [DPMiniShortcut.current sameKey:DPMiniShortcut.defaultShortcut], @"a failed disk write rolls back preferences and preserves the working registration");
    NSCAssert(DPMiniSaveShortcut(custom, NO, &error) && [DPMiniShortcut.current sameKey:custom]
        && DPNewMiniItem.keyEquivalentModifierMask == custom.modifiers && [DPNewMiniItem.keyEquivalent isEqual:@"m"], @"saving updates the global and menu shortcut together");
    NSUserDefaults *reloaded = [[NSUserDefaults alloc] initWithSuiteName:@(getenv("DIATWEAKS_DOMAIN"))];
    NSCAssert([[reloaded dictionaryForKey:@"diaMiniShortcut"] isEqual:custom.dictionary], @"a fresh preferences instance reads the complete saved shortcut");
    NSCAssert([DPReadShortcutInNewProcess() isEqual:custom.dictionary], @"a separate process reads the saved shortcut from disk");
    NSCAssert(![[DPMiniShortcut alloc] initWithCode:kVK_ANSI_N modifiers:NSEventModifierFlagShift characters:@"n"], @"plain typing and Shift alone are not global shortcuts");
    [defaults setObject:@{@"keyCode":@999, @"modifiers":@(standard), @"characters":@"n"} forKey:@"diaMiniShortcut"];
    NSCAssert([DPMiniShortcut.current sameKey:DPMiniShortcut.defaultShortcut], @"malformed saved keys fall back to the default");
    [defaults setObject:custom.dictionary forKey:@"diaMiniShortcut"];

    NSMenu *file = NSApp.mainMenu.itemArray.firstObject.submenu;
    NSMenuItem *reserved = [[NSMenuItem alloc] initWithTitle:@"Reserved fixture action" action:nil keyEquivalent:@"r"];
    reserved.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift; [file addItem:reserved];
    DPMiniShortcut *collision = [[DPMiniShortcut alloc] initWithCode:kVK_ANSI_R modifiers:reserved.keyEquivalentModifierMask characters:@"r"];
    NSUInteger attempts = DPFixtureRegistrations;
    NSCAssert(!DPMiniSaveShortcut(collision, NO, &error) && [error containsString:reserved.title] && attempts == DPFixtureRegistrations,
        @"native menu shortcuts are rejected before registration");
    [file removeItem:reserved];

    DPDiaMini.on = NO; DPBrowseApply(&DPDiaMini); attempts = DPFixtureRegistrations;
    DPMiniShortcut *disabled = [[DPMiniShortcut alloc] initWithCode:kVK_ANSI_K modifiers:standard characters:@"k"];
    NSCAssert(DPMiniSaveShortcut(disabled, NO, &error) && !DPBrowseHotkeyRegistered() && DPFixtureRegistrations == attempts,
        @"a shortcut can be configured while Mini is off without activating it");
    DPDiaMini.on = YES; DPBrowseApply(&DPDiaMini);
    NSCAssert(DPFixtureHotkeyCode == kVK_ANSI_K, @"enabling Mini uses the saved shortcut");
    NSCAssert(DPMiniSaveShortcut(DPMiniShortcut.defaultShortcut, YES, &error) && ![defaults objectForKey:@"diaMiniShortcut"], @"reset removes the override and restores the default");
    DPTestMiniShortcutSettings();
}
