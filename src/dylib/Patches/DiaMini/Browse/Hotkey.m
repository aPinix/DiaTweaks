#import "../Shortcuts/Shortcut.h"
#import "Patches/CommandBar/CommandBar.h"
#import "WindowCommand.h"

static EventHotKeyRef DPMiniHotkey;
static EventHandlerRef DPMiniHotkeyHandler;
static DPMiniShortcut *DPRegisteredShortcut;
static BOOL DPMiniHotkeyPaused;
static NSString *DPMiniHotkeyError;
NSNotificationName const DPMiniShortcutDidChangeNotification = @"DPMiniShortcutDidChange";

static OSStatus DPMiniPressed(EventHandlerCallRef next, EventRef event, void *context) {
    EventHotKeyID key;
    if (GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof key, NULL, &key) != noErr
        || key.signature != 'DPMN' || key.id != 1) return eventNotHandledErr;
    if (!DPMiniHotkeyPaused && DPDiaMini.on) dispatch_async(dispatch_get_main_queue(), ^{ DPBrowseShowLauncher(); });
    return noErr;
}
BOOL DPBrowseHotkeyRegistered(void) { return DPMiniHotkey != NULL; }
BOOL DPBrowseHotkeyPaused(void) { return DPMiniHotkeyPaused; }
NSString *DPBrowseHotkeyError(void) { return DPMiniHotkeyError; }

static OSStatus DPRegisterShortcut(DPMiniShortcut *shortcut, EventHotKeyRef *result) {
    if (!DPMiniHotkeyHandler) {
        EventTypeSpec spec = {kEventClassKeyboard, kEventHotKeyPressed};
        OSStatus status = InstallApplicationEventHandler(DPMiniPressed, 1, &spec, NULL, &DPMiniHotkeyHandler);
        if (status != noErr) return status;
    }
    EventHotKeyID key = {'DPMN', 1};
    return RegisterEventHotKey(shortcut.keyCode, shortcut.carbonModifiers, key, GetApplicationEventTarget(), kEventHotKeyExclusive, result);
}
void DPBrowseStopHotkey(void) {
    if (DPMiniHotkey) UnregisterEventHotKey(DPMiniHotkey);
    DPMiniHotkey = NULL;
    DPRegisteredShortcut = nil;
}
void DPBrowseUpdateHotkey(void) {
    DPMiniShortcut *shortcut = DPMiniShortcut.current;
    DPNewMiniItem.keyEquivalent = DPMiniHotkeyPaused ? @"" : shortcut.characters;
    DPNewMiniItem.keyEquivalentModifierMask = shortcut.modifiers;
    if (!DPDiaMini.on || DPMiniHotkeyPaused) { DPBrowseStopHotkey(); if (!DPDiaMini.on) DPMiniHotkeyError = nil; }
    else if (!DPMiniHotkey || ![DPRegisteredShortcut sameKey:shortcut]) {
        DPBrowseStopHotkey();
        OSStatus status = DPRegisterShortcut(shortcut, &DPMiniHotkey);
        DPMiniHotkeyError = status == noErr ? nil : @"Shortcut unavailable. Choose another shortcut or use File → New Dia Mini.";
        if (status == noErr) DPRegisteredShortcut = shortcut;
    }
    DPNewMiniItem.toolTip = DPMiniHotkeyError ?: [NSString stringWithFormat:@"Open Dia Mini from any app (%@)", shortcut.label];
    [NSNotificationCenter.defaultCenter postNotificationName:DPMiniShortcutDidChangeNotification object:nil];
}
void DPBrowsePauseHotkey(BOOL paused) { DPMiniHotkeyPaused = paused; DPBrowseUpdateHotkey(); }

BOOL DPMiniSaveShortcut(DPMiniShortcut *shortcut, BOOL reset, NSString **error) {
    if (error) *error = nil;
    NSString *problem = shortcut ? DPBrowseReservedMiniShortcut(shortcut) ?: DPCommandBarMiniShortcutConflict(shortcut) ?: DPMiniShortcutMenuConflict(shortcut, NSApp.mainMenu)
        : @"Include Command, Control or Option with a key.";
    if (problem) { if (error) *error = problem; return NO; }
    EventHotKeyRef replacement = NULL;
    if (DPDiaMini.on && ![DPRegisteredShortcut sameKey:shortcut]) {
        OSStatus status = DPRegisterShortcut(shortcut, &replacement);
        if (status != noErr) {
            if (error) *error = status == eventHotKeyExistsErr ? @"That shortcut is already in use. Try another." : @"Couldn’t use that shortcut. Try another.";
            return NO;
        }
    }
    NSUserDefaults *defaults = DPMiniShortcutDefaults();
    id previous = [defaults objectForKey:@"diaMiniShortcut"];
    if (reset) [defaults removeObjectForKey:@"diaMiniShortcut"];
    else [defaults setObject:shortcut.dictionary forKey:@"diaMiniShortcut"];
    if (![defaults synchronize]) {
        if (previous) [defaults setObject:previous forKey:@"diaMiniShortcut"];
        else [defaults removeObjectForKey:@"diaMiniShortcut"];
        [defaults synchronize];
        if (replacement) UnregisterEventHotKey(replacement);
        if (error) *error = @"Couldn’t save the shortcut. Try again.";
        return NO;
    }
    // Keep the working registration until both the replacement and its preference write succeed.
    if (replacement) { DPBrowseStopHotkey(); DPMiniHotkey = replacement; DPRegisteredShortcut = shortcut; }
    DPMiniHotkeyError = nil;
    if (!DPMiniHotkeyPaused) DPBrowseUpdateHotkey();
    return YES;
}
