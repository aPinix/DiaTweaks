#import "Launcher.h"
#import <Carbon/Carbon.h>

static EventHotKeyRef DPMiniHotkey;
static EventHandlerRef DPMiniHotkeyHandler;

static OSStatus DPMiniPressed(EventHandlerCallRef next, EventRef event, void *context) {
    EventHotKeyID key;
    if (GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof key, NULL, &key) != noErr
        || key.signature != 'DPMN' || key.id != 1) return eventNotHandledErr;
    dispatch_async(dispatch_get_main_queue(), ^{ DPBrowseShowLauncher(); });
    return noErr;
}
BOOL DPBrowseHotkeyRegistered(void) { return DPMiniHotkey != NULL; }
void DPBrowseUpdateHotkey(void) {
    if (!DPDiaMini.on) { DPBrowseStopHotkey(); return; }
    if (DPMiniHotkey) return;
    if (!DPMiniHotkeyHandler) {
        EventTypeSpec spec = {kEventClassKeyboard, kEventHotKeyPressed};
        InstallApplicationEventHandler(DPMiniPressed, 1, &spec, NULL, &DPMiniHotkeyHandler);
    }
    EventHotKeyID key = {'DPMN', 1};
    OSStatus status = RegisterEventHotKey(kVK_ANSI_N, controlKey | optionKey | cmdKey, key, GetApplicationEventTarget(), 0, &DPMiniHotkey);
    DPNewMiniItem.toolTip = status == noErr ? @"Open Dia Mini from any app (⌃⌥⌘N)" : @"The global shortcut is already in use. Use this menu command.";
    if (status != noErr) NSLog(@"DiaPatches: couldn't register the Dia Mini shortcut (%d)", (int)status);
}
void DPBrowseStopHotkey(void) {
    if (DPMiniHotkey) UnregisterEventHotKey(DPMiniHotkey);
    DPMiniHotkey = NULL;
}
