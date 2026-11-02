#import "CommandBar.h"
#import "Patches/DiaMini/Browse/WindowCommand.h"

BOOL DPCommandBarHandleEvent(NSEvent *event) {
    if (event.type != NSEventTypeKeyDown || !DPCommandBar.on || DPCommandBar.unavailable
        || DPCommandBarShortcutPaused() || DPBrowseHotkeyPaused()) return NO;
    DPMiniShortcut *pressed = [DPMiniShortcut fromEvent:event];
    if (![DPCommandBarShortcut.current sameKey:pressed] || DPCommandBarShortcutError()) return NO;
    if (!event.isARepeat) {
        DPBrowseWindow *mini = DPBrowseMiniForWindow(event.window);
        if (mini) DPBrowseEditMini(mini, NO);
        else DPCommandBarShow();
    }
    return YES;
}
void DPCommandBarInstallKeyboard(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        DPCommandBarItem = DPAddMenuItem(@"File", @"Command Bar", ^{ DPCommandBarShow(); });
        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
            return DPCommandBarHandleEvent(event) ? nil : event;
        }];
        [NSNotificationCenter.defaultCenter addObserverForName:DPMiniShortcutDidChangeNotification object:nil queue:nil
            usingBlock:^(NSNotification *note) { DPCommandBarUpdateBinding(); }];
    });
}
