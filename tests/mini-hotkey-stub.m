#import "mini-shortcuts.h"

OSStatus DPFixtureHotkeyStatus;
UInt32 DPFixtureHotkeyCode, DPFixtureHotkeyModifiers, DPFixtureHotkeyOptions;
NSUInteger DPFixtureRegistrations, DPFixtureUnregistrations;

// Keep fixtures independent of the shortcuts owned by the user's running apps.
OSStatus RegisterEventHotKey(UInt32 code, UInt32 modifiers, EventHotKeyID key, EventTargetRef target, OptionBits options, EventHotKeyRef *result) {
    DPFixtureRegistrations++;
    if (DPFixtureHotkeyStatus != noErr) return DPFixtureHotkeyStatus;
    DPFixtureHotkeyCode = code; DPFixtureHotkeyModifiers = modifiers; DPFixtureHotkeyOptions = options;
    *result = (EventHotKeyRef)(uintptr_t)(DPFixtureRegistrations + 100);
    return noErr;
}
OSStatus UnregisterEventHotKey(EventHotKeyRef ref) { DPFixtureUnregistrations++; return noErr; }

@implementation DPFixtureShortcutPage
- (void)sync {}
@end
