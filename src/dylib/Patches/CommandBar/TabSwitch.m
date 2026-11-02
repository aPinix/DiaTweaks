#import "OpenTabs.h"
#import <objc/message.h>

BOOL DPCommandBarActivateTab(DPCommandTabSuggestion *tab, DPBrowseSource *source) {
    if (!DPCommandBar.on || DPCommandBar.unavailable || !DPCommandBarTabIsCurrent(tab, source)) return NO;
    id contents = tab.contents;
    DPBrowseSource *current = DPCommandBarSourceForTab(contents, source);
    if (!current) return NO;
    @try {
        ((void (*)(id, SEL, id, BOOL))objc_msgSend)(current.delegate, @selector(webContentsSelect:shouldActivate:), contents, YES);
        [current.window makeKeyAndOrderFront:nil];
        return YES;
    } @catch (NSException *exception) { return NO; }
}
