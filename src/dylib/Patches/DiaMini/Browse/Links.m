#import "QuickBrowse.h"
#import <objc/message.h>

static BOOL DPBrowse_context(id self, SEL _cmd, id contents, NSMenu *menu, id element) {
    BOOL result = DPCallOriginal(DPBrowse_context, self, contents, menu, element);
    if (![element respondsToSelector:@selector(linkURL)]) return result;
    id (*get)(id, SEL) = (void *)objc_msgSend;
    NSURL *url = DPBrowseURL(get(element, @selector(linkURL)));
    DPBrowseSource *source = DPBrowseSourceFor(contents);
    if (!url || !source || !DPDiaMini.on) return result;
    if (menu.numberOfItems) [menu addItem:NSMenuItem.separatorItem];
    [menu addItem:DPMenuItem(@"Open Link in Dia Mini", ^{ DPBrowseShow(url, source); })];
    return result;
}

void DPBrowseInstallDelegateHooks(Class cls) {
    DPHookClass(cls, @selector(webContents:willShowContextMenu:withElement:), (IMP)DPBrowse_context);
}

void DPBrowseInstallEvents(void) {
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
        handler:^NSEvent *(NSEvent *event) {
            for (DPBrowseWindow *preview in DPBrowseWindows.copy) {
                if (preview.window != event.window || event.type != NSEventTypeKeyDown) continue;
                NSEventModifierFlags mods = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
                if (event.keyCode == 53 && !mods) { [preview close]; return nil; }
                if ((mods & NSEventModifierFlagCommand) && [event.charactersIgnoringModifiers.lowercaseString isEqual:@"l"]) {
                    [preview.window makeFirstResponder:preview.address]; [preview.address selectText:nil]; return nil;
                }
                if ((mods & NSEventModifierFlagCommand) && event.keyCode == 36) { [preview promote:nil]; return nil; }
            }
            return event;
        }];
}
