#import "CommandBar.h"
#import "Settings/Settings.h"

static NSView *DPCommandShortcutRow(void) {
    DPCommandBarRecorder *recorder = [DPCommandBarRecorder new];
    NSTextField *hint = DPLabel(@"", 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
    recorder.hint = hint; [recorder refresh];
    NSButton *reset = [NSButton buttonWithTitle:@"Reset" target:recorder action:@selector(resetShortcut:)];
    reset.accessibilityLabel = @"Reset Command Bar keyboard shortcut";
    NSStackView *buttons = [NSStackView stackViewWithViews:@[recorder, reset]]; buttons.spacing = 8;
    [recorder.widthAnchor constraintGreaterThanOrEqualToConstant:125].active = YES;
    return DPGroup(@[DPRow(DPColumn(@[DPLabel(@"Keyboard shortcut", 13, NSFontWeightRegular, NSColor.labelColor), hint], 2), buttons)]);
}
static void DPCommandPage_sync(NSStackView *self, SEL _cmd) {
    DPCallOriginal(DPCommandPage_sync, self);
    NSView *toggle = DPFindView(self, ^BOOL(NSView *view) { return [view isKindOfClass:NSSwitch.class] && DPHasLabel(view, @"Command Bar"); });
    if (!toggle || DPFindView(self, ^BOOL(NSView *view) { return [view isKindOfClass:DPCommandBarRecorder.class]; })) return;
    NSView *row = DPCommandShortcutRow();
    [self insertArrangedSubview:row atIndex:MIN(2, self.arrangedSubviews.count)];
    [row.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
    [self setCustomSpacing:20 afterView:row];
}
void DPCommandBarInstallSettings(void) { DPHook("DPPageView", @selector(sync), (IMP)DPCommandPage_sync); }
