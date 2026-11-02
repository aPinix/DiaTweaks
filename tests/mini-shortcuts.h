#import "Patches/DiaMini/Shortcuts/Shortcut.h"

@interface DPFixtureShortcutPage : NSStackView
- (void)sync;
@end
extern OSStatus DPFixtureHotkeyStatus;
extern UInt32 DPFixtureHotkeyCode, DPFixtureHotkeyModifiers, DPFixtureHotkeyOptions;
extern NSUInteger DPFixtureRegistrations, DPFixtureUnregistrations;
void DPTestMiniShortcutSettings(void);
void DPTestMiniShortcuts(void);
