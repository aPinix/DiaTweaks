#import "Shortcut.h"

@implementation DPMiniShortcutRecorder (Binding)
- (DPMiniShortcut *)currentShortcut { return DPMiniShortcut.current; }
- (DPMiniShortcut *)defaultShortcut { return DPMiniShortcut.defaultShortcut; }
- (BOOL)saveShortcut:(DPMiniShortcut *)shortcut reset:(BOOL)reset error:(NSString **)error {
    return DPMiniSaveShortcut(shortcut, reset, error);
}
- (void)pauseShortcut:(BOOL)paused { DPBrowsePauseHotkey(paused); }
- (NSNotificationName)shortcutNotificationName { return DPMiniShortcutDidChangeNotification; }
- (NSString *)shortcutRegistrationError { return DPBrowseHotkeyError(); }
- (BOOL)shortcutUnavailable { return DPDiaMini.unavailable; }
@end
