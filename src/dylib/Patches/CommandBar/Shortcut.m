#import "CommandBar.h"

NSNotificationName const DPCommandBarShortcutDidChangeNotification = @"DPCommandBarShortcutDidChange";

@implementation DPCommandBarShortcut
+ (instancetype)defaultShortcut { return [[self alloc] initWithCode:kVK_ANSI_K modifiers:NSEventModifierFlagCommand characters:@"k"]; }
+ (instancetype)current {
    id saved = [DPMiniShortcutDefaults() objectForKey:@"commandBarShortcut"];
    if (![saved isKindOfClass:NSDictionary.class]) return self.defaultShortcut;
    id code = saved[@"keyCode"], flags = saved[@"modifiers"], chars = saved[@"characters"];
    if (![code isKindOfClass:NSNumber.class] || ![flags isKindOfClass:NSNumber.class] || ![chars isKindOfClass:NSString.class]) return self.defaultShortcut;
    return [[self alloc] initWithCode:[code unsignedIntValue] modifiers:[flags unsignedIntegerValue] characters:chars] ?: self.defaultShortcut;
}
@end

NSString *DPCommandBarMiniShortcutConflict(DPMiniShortcut *shortcut) {
    return [DPCommandBarShortcut.current sameKey:shortcut] ? @"Already used by Command Bar. Choose another shortcut." : nil;
}
NSString *DPCommandBarShortcutError(void) { return DPCommandBarShortcutConflict(DPCommandBarShortcut.current, NSApp.mainMenu); }

BOOL DPCommandBarSaveShortcut(DPMiniShortcut *shortcut, BOOL reset, NSString **error) {
    if (error) *error = nil;
    NSString *problem = DPCommandBarShortcutConflict(shortcut, NSApp.mainMenu);
    if (problem) { if (error) *error = problem; return NO; }
    NSUserDefaults *defaults = DPMiniShortcutDefaults();
    id previous = [defaults objectForKey:@"commandBarShortcut"];
    if (reset) [defaults removeObjectForKey:@"commandBarShortcut"];
    else [defaults setObject:shortcut.dictionary forKey:@"commandBarShortcut"];
    if (![defaults synchronize]) {
        if (previous) [defaults setObject:previous forKey:@"commandBarShortcut"];
        else [defaults removeObjectForKey:@"commandBarShortcut"];
        [defaults synchronize];
        if (error) *error = @"Couldn’t save the shortcut. Try again.";
        return NO;
    }
    DPCommandBarUpdateBinding();
    return YES;
}
