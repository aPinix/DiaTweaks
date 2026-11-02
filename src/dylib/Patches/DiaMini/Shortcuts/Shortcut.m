#import "Shortcut.h"

NSUserDefaults *DPMiniShortcutDefaults(void) {
    static NSUserDefaults *defaults;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        const char *domain = getenv("DIATWEAKS_DOMAIN");
        defaults = [[NSUserDefaults alloc] initWithSuiteName:domain && *domain ? @(domain) : @"com.diapatches"];
    });
    return defaults;
}

@implementation DPMiniShortcut
- (instancetype)initWithCode:(UInt32)code modifiers:(NSEventModifierFlags)modifiers characters:(NSString *)characters {
    NSEventModifierFlags allowed = NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift;
    modifiers &= allowed;
    if (code > 127 || (code >= 54 && code <= 63) || characters.length != 1
        || !(modifiers & ~NSEventModifierFlagShift)) return nil;
    if (!(self = [super init])) return nil;
    _keyCode = code; _modifiers = modifiers; _characters = characters.lowercaseString.copy;
    return self;
}
+ (instancetype)defaultShortcut {
    return [[self alloc] initWithCode:kVK_ANSI_N modifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand characters:@"n"];
}
+ (instancetype)current {
    id saved = [DPMiniShortcutDefaults() objectForKey:@"diaMiniShortcut"];
    if (![saved isKindOfClass:NSDictionary.class]) return self.defaultShortcut;
    id code = saved[@"keyCode"], flags = saved[@"modifiers"], chars = saved[@"characters"];
    if (![code isKindOfClass:NSNumber.class] || ![flags isKindOfClass:NSNumber.class] || ![chars isKindOfClass:NSString.class]) return self.defaultShortcut;
    return [[self alloc] initWithCode:[code unsignedIntValue] modifiers:[flags unsignedIntegerValue] characters:chars] ?: self.defaultShortcut;
}
+ (instancetype)fromEvent:(NSEvent *)event {
    return [[self alloc] initWithCode:event.keyCode modifiers:event.modifierFlags characters:event.charactersIgnoringModifiers];
}
- (BOOL)sameKey:(DPMiniShortcut *)other { return other && self.keyCode == other.keyCode && self.modifiers == other.modifiers; }
- (NSDictionary *)dictionary { return @{@"keyCode": @(self.keyCode), @"modifiers": @(self.modifiers), @"characters": self.characters}; }
- (UInt32)carbonModifiers {
    return ((self.modifiers & NSEventModifierFlagCommand) ? cmdKey : 0)
        | ((self.modifiers & NSEventModifierFlagOption) ? optionKey : 0)
        | ((self.modifiers & NSEventModifierFlagControl) ? controlKey : 0)
        | ((self.modifiers & NSEventModifierFlagShift) ? shiftKey : 0);
}
- (NSString *)label {
    NSMutableString *text = [NSMutableString new];
    if (self.modifiers & NSEventModifierFlagControl) [text appendString:@"⌃"];
    if (self.modifiers & NSEventModifierFlagOption) [text appendString:@"⌥"];
    if (self.modifiers & NSEventModifierFlagShift) [text appendString:@"⇧"];
    if (self.modifiers & NSEventModifierFlagCommand) [text appendString:@"⌘"];
    NSDictionary *special = @{@36:@"↩", @48:@"⇥", @49:@"Space", @51:@"⌫", @53:@"⎋", @76:@"⌤", @117:@"⌦", @123:@"←", @124:@"→", @125:@"↓", @126:@"↑"};
    unichar character = [self.characters characterAtIndex:0];
    NSString *key = special[@(self.keyCode)] ?: (character >= NSF1FunctionKey && character <= NSF35FunctionKey
        ? [NSString stringWithFormat:@"F%u", character - NSF1FunctionKey + 1] : self.characters.uppercaseString);
    return [text stringByAppendingString:key];
}
@end
