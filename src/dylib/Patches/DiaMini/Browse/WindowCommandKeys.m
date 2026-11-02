#import "WindowCommand.h"
#import "../Shortcuts/Shortcut.h"
#import "BrowserExtensions.h"
#import "BrowserToolbar.h"

NSString *DPBrowseReservedMiniShortcut(DPMiniShortcut *shortcut) {
    if (shortcut.modifiers != NSEventModifierFlagCommand) return nil;
    NSString *key = shortcut.characters;
    if ([key isEqual:@"l"]) return @"Reserved for editing Mini’s address. Choose another shortcut.";
    if ([key isEqual:@"w"]) return @"Reserved for closing the Mini window. Choose another shortcut.";
    if ([key isEqual:@"o"] || shortcut.keyCode == 36 || shortcut.keyCode == 76)
        return @"Reserved for Open in Dia in Mini. Choose another shortcut.";
    return [@[@"r", @"[", @"]"] containsObject:key] ? @"Reserved for Mini navigation. Choose another shortcut." : nil;
}

BOOL DPBrowseHandleMiniKeyEvent(NSEvent *event) {
    if (event.type != NSEventTypeKeyDown || !DPDiaMini.on || DPBrowseHotkeyPaused()) return NO;
    DPBrowseWindow *owner = DPBrowseMiniForWindow(event.window);
    if (!owner || owner.closing || owner.transferred) return NO;
    NSEventModifierFlags mask = NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagControl | NSEventModifierFlagShift;
    NSEventModifierFlags flags = event.modifierFlags & mask;
    NSString *key = event.charactersIgnoringModifiers.lowercaseString;
    if (owner.promoting) return (!flags && event.keyCode == 53) || (flags == NSEventModifierFlagCommand
        && ([@[@"l", @"t", @"w", @"o", @"r", @"[", @"]"] containsObject:key] || event.keyCode == 36 || event.keyCode == 76));
    BOOL chooser = owner.destinationPopover.shown && owner.destinationPopover.contentViewController.view.window == event.window;
    NSPopover *extensions = DPBrowseMiniExtensionsPopover(owner);
    if (extensions.shown && extensions.contentViewController.view.window == event.window
        && ((!flags && event.keyCode == 53) || (flags == NSEventModifierFlagCommand && [key isEqual:@"w"]))) {
        DPBrowseCloseMiniExtensions(owner); return YES;
    }
    if (chooser && ((!flags && event.keyCode == 53) || (flags == NSEventModifierFlagCommand && [key isEqual:@"w"]))) {
        [owner.destinationPopover close]; return YES;
    }
    if (flags == NSEventModifierFlagCommand && [@[@"l", @"t"] containsObject:key]) {
        if (!event.isARepeat) DPBrowseEditMini(owner, [key isEqual:@"l"]); return YES;
    }
    if (flags == NSEventModifierFlagCommand && [key isEqual:@"w"]) {
        if (!event.isARepeat) {
            DPMiniLauncher *palette = DPCurrentMiniLauncher;
            if (palette.window == event.window) { palette.restorePrevious = YES; [palette close]; }
            else [owner close];
        }
        return YES;
    }
    if (!flags && event.keyCode == 53 && event.window == owner.window) { [owner close]; return YES; }
    BOOL promote = [key isEqual:@"o"] || event.keyCode == 36 || event.keyCode == 76;
    BOOL navigation = [@[@"r", @"[", @"]"] containsObject:key];
    if (flags != NSEventModifierFlagCommand || (!promote && !navigation)) return NO;
    if (event.isARepeat) return YES;
    DPMiniWindowCommand *palette = [DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class] ? (id)DPCurrentMiniLauncher : nil;
    if (palette.miniOwner == owner) { palette.restorePrevious = NO; [palette close]; }
    [owner.destinationPopover close];
    DPBrowseCloseMiniExtensions(owner);
    [owner.window makeKeyAndOrderFront:nil]; [owner.window makeFirstResponder:owner.contents.nativeView];
    if (promote) [owner promote:nil];
    else if ([key isEqual:@"r"]) [owner reload:nil];
    else if ([key isEqual:@"["]) [owner back:nil];
    else [owner forward:nil];
    return YES;
}
