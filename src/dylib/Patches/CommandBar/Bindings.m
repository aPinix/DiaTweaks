#import "CommandBar.h"

NSMenuItem *DPCommandBarItem;
static NSMapTable<NSMenuItem *, NSDictionary *> *DPCommandNativeBindings;
static BOOL DPCommandPaused;
static NSEventModifierFlags DPCommandFlags(NSEventModifierFlags flags) {
    return flags & (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift);
}
static BOOL DPCommandMayTakeOver(DPMiniShortcut *shortcut) {
    return shortcut.modifiers == NSEventModifierFlagCommand && [@[@"k", @"t"] containsObject:shortcut.characters];
}
static BOOL DPCommandMatches(NSMenuItem *item, DPMiniShortcut *shortcut) {
    NSEventModifierFlags flags = DPCommandFlags(item.keyEquivalentModifierMask);
    if (![item.keyEquivalent isEqual:item.keyEquivalent.lowercaseString]) flags |= NSEventModifierFlagShift;
    return item.keyEquivalent.length && flags == shortcut.modifiers && [item.keyEquivalent.lowercaseString isEqual:shortcut.characters];
}
NSString *DPCommandBarShortcutConflict(DPMiniShortcut *shortcut, NSMenu *menu) {
    if (!shortcut) return @"Include Command, Control or Option with a key.";
    if ([DPMiniShortcut.current sameKey:shortcut]) return @"Already used by Dia Mini. Choose another shortcut.";
    for (NSMenuItem *item in menu.itemArray) {
        if (item == DPCommandBarItem || item.hidden) continue;
        if (DPCommandMatches(item, shortcut) && !DPCommandMayTakeOver(shortcut))
            return [NSString stringWithFormat:@"Already used by “%@” in Dia. Choose another shortcut.", item.title];
        NSString *nested = item.submenu ? DPCommandBarShortcutConflict(shortcut, item.submenu) : nil;
        if (nested) return nested;
    }
    return nil;
}
void DPCommandBarRestoreBindings(void) {
    for (NSMenuItem *item in DPCommandNativeBindings.keyEnumerator.allObjects) {
        NSDictionary *saved = [DPCommandNativeBindings objectForKey:item];
        if (!item.keyEquivalent.length) { item.keyEquivalent = saved[@"key"]; item.keyEquivalentModifierMask = [saved[@"flags"] unsignedIntegerValue]; }
    }
    [DPCommandNativeBindings removeAllObjects];
}
static void DPCommandClaim(NSMenu *menu, DPMiniShortcut *shortcut) {
    for (NSMenuItem *item in menu.itemArray) {
        if (item == DPCommandBarItem) continue;
        if (DPCommandMatches(item, shortcut)) {
            if (!DPCommandNativeBindings) DPCommandNativeBindings = [NSMapTable weakToStrongObjectsMapTable];
            [DPCommandNativeBindings setObject:@{@"key":item.keyEquivalent, @"flags":@(item.keyEquivalentModifierMask)} forKey:item];
            item.keyEquivalent = @"";
        }
        if (item.submenu) DPCommandClaim(item.submenu, shortcut);
    }
}
BOOL DPCommandBarShortcutPaused(void) { return DPCommandPaused; }
void DPCommandBarUpdateBinding(void) {
    DPCommandBarRestoreBindings();
    DPMiniShortcut *shortcut = DPCommandBarShortcut.current;
    BOOL active = DPCommandBar.on && !DPCommandBar.unavailable && !DPCommandPaused && !DPBrowseHotkeyPaused()
        && !DPCommandBarShortcutConflict(shortcut, NSApp.mainMenu);
    DPCommandBarItem.hidden = !DPCommandBar.on;
    if (active && DPCommandMayTakeOver(shortcut)) DPCommandClaim(NSApp.mainMenu, shortcut);
    DPCommandBarItem.keyEquivalent = active ? shortcut.characters : @"";
    DPCommandBarItem.keyEquivalentModifierMask = shortcut.modifiers;
    DPCommandBarItem.toolTip = [NSString stringWithFormat:@"Open Command Bar in Dia (%@)", shortcut.label];
    [NSNotificationCenter.defaultCenter postNotificationName:DPCommandBarShortcutDidChangeNotification object:nil];
}
void DPCommandBarPauseShortcut(BOOL paused) { DPCommandPaused = paused; DPCommandBarUpdateBinding(); }
