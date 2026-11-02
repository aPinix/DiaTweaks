#import "CommandBar.h"
#import "OpenTabs.h"

static NSString *DPVerifyCommandBar(DPPatch *patch) {
    if (patch->on && !DPBrowseCompatible()) return @"Dia’s native tab APIs are unavailable";
    if (DPCommandBarItem && DPCommandBarItem.hidden == patch->on) return @"the Command Bar menu does not match its switch";
    for (NSView *root in DPFindViews("DPMiniSearchRoot")) {
        if (![root.window.identifier isEqual:@"DiaTweaks.CommandBar"]) continue;
        if (!patch->on) return @"a disabled Command Bar is still open";
        if (!DPFindView(root, ^BOOL(NSView *view) { return [view isKindOfClass:NSTextField.class] && ((NSTextField *)view).editable; })
            || !DPFindView(root, ^BOOL(NSView *view) { return [view isKindOfClass:NSTableView.class]; }))
            return @"the Command Bar search field or choices are missing";
    }
    for (NSView *page in DPFindViews("DPPageView")) {
        BOOL command = DPFindView(page, ^BOOL(NSView *view) { return [view isKindOfClass:NSSwitch.class] && DPHasLabel(view, @"Command Bar"); }) != nil;
        if (command && !DPFindView(page, ^BOOL(NSView *view) { return [view isKindOfClass:DPCommandBarRecorder.class]; }))
            return @"the Command Bar shortcut control is missing";
    }
    return nil;
}
static void DPApplyCommandBar(DPPatch *patch) {
    DPCommandBarUpdateBinding();
    if (!patch->on) DPCommandBarClose();
}
static void DPInstallCommandBar(void) {
    DPInstallQuickBrowse();
    DPCommandBarInstallSettings();
    DPOnLaunch(^{ DPCommandBarInstallTabLookup(); DPCommandBarInstallKeyboard(); DPCommandBarUpdateBinding(); });
    DPOnQuit(^{ DPCommandBarClose(); DPCommandBarRestoreBindings(); });
}

DP_PATCH(DPCommandBar) {
    .key = @"commandBar", .order = 230,
    .title = @"Command Bar",
    .detail = @"Default shortcut: ⌘K in Dia. Change it below, including ⌘T. Search, enter an address or use site search in a centered command bar. Enter opens a normal tab in the current window and profile. Experimental.",
    .symbol = @"command", .tint = @"systemIndigoColor", .section = @"Browsing",
    .classes = DPClasses(DPDiaBrowserApplication, DPDiaBrowser, DPDiaBrowserContext, DPDiaWebContents,
        DPDiaWebContentsConfiguration, DPDiaBrowserDelegate, DPDiaWebContent, DPDiaTablessDelegate),
    .install = DPInstallCommandBar, .apply = DPApplyCommandBar, .verify = DPVerifyCommandBar,
};
