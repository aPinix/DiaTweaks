#import "CommandBar.h"

@implementation DPCommandBarRecorder
- (instancetype)initWithFrame:(NSRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.accessibilityLabel = @"Command Bar keyboard shortcut";
    return self;
}
- (DPMiniShortcut *)currentShortcut { return DPCommandBarShortcut.current; }
- (DPMiniShortcut *)defaultShortcut { return DPCommandBarShortcut.defaultShortcut; }
- (BOOL)saveShortcut:(DPMiniShortcut *)shortcut reset:(BOOL)reset error:(NSString **)error {
    return DPCommandBarSaveShortcut(shortcut, reset, error);
}
- (void)pauseShortcut:(BOOL)paused { [super pauseShortcut:paused]; DPCommandBarPauseShortcut(paused); }
- (NSNotificationName)shortcutNotificationName { return DPCommandBarShortcutDidChangeNotification; }
- (NSString *)shortcutRegistrationError { return DPCommandBarShortcutError(); }
- (BOOL)shortcutUnavailable { return DPCommandBar.unavailable; }
@end
