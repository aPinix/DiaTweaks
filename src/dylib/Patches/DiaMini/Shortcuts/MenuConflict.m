#import "Shortcut.h"

NSString *DPMiniShortcutMenuConflict(DPMiniShortcut *shortcut, NSMenu *menu) {
    NSEventModifierFlags allowed = NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift;
    for (NSMenuItem *item in menu.itemArray) {
        if (item == DPNewMiniItem || item.hidden) continue;
        NSEventModifierFlags flags = item.keyEquivalentModifierMask & allowed;
        if (![item.keyEquivalent isEqual:item.keyEquivalent.lowercaseString]) flags |= NSEventModifierFlagShift;
        if (item.keyEquivalent.length && flags == shortcut.modifiers && [item.keyEquivalent.lowercaseString isEqual:shortcut.characters])
            return [NSString stringWithFormat:@"Already used by “%@” in Dia. Choose another shortcut.", item.title];
        NSString *nested = item.submenu ? DPMiniShortcutMenuConflict(shortcut, item.submenu) : nil;
        if (nested) return nested;
    }
    return nil;
}
