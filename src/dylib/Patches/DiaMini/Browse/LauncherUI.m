#import "Launcher.h"

@interface DPMiniSearchPanel : NSWindow
@end
@implementation DPMiniSearchPanel
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
@end
@interface DPMiniSearchRoot : NSVisualEffectView
@end
@implementation DPMiniSearchRoot
- (BOOL)isFlipped { return YES; }
- (void)updateSurface {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.layer.backgroundColor = [NSColor.controlBackgroundColor colorWithAlphaComponent:0.98].CGColor;
        self.layer.borderColor = NSColor.separatorColor.CGColor;
    }];
}
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateSurface]; }
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateSurface]; }
@end
@interface DPMiniSuggestionTable : NSTableView
@end
@implementation DPMiniSuggestionTable
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (void)keyDown:(NSEvent *)event {
    if (event.keyCode == 53) [self.window close];
    else if (event.keyCode == 36 || event.keyCode == 76) [NSApp sendAction:self.action to:self.target from:self];
    else [super keyDown:event];
}
@end

@implementation DPMiniLauncher (UI)
- (void)buildLauncher {
    NSScreen *screen = NSScreen.mainScreen;
    for (NSScreen *candidate in NSScreen.screens) if (NSPointInRect(NSEvent.mouseLocation, candidate.frame)) { screen = candidate; break; }
    NSRect frame = DPBrowseLauncherFrame(screen.visibleFrame, 130);
    CGFloat width = NSWidth(frame);
    NSWindow *panel = [[DPMiniSearchPanel alloc] initWithContentRect:frame styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered defer:NO];
    panel.title = @"Dia Mini"; panel.identifier = @"DiaTweaks.MiniLauncher";
    panel.appearance = self.source.window.effectiveAppearance ?: NSApp.effectiveAppearance;
    panel.level = NSFloatingWindowLevel; panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    panel.backgroundColor = NSColor.clearColor; panel.opaque = NO; panel.hasShadow = NO;
    panel.movableByWindowBackground = YES; panel.releasedWhenClosed = NO; panel.delegate = self;
    self.window = panel;
    DPMiniSearchRoot *root = [[DPMiniSearchRoot alloc] initWithFrame:NSMakeRect(0, 0, width, 110)];
    root.material = NSVisualEffectMaterialPopover; root.blendingMode = NSVisualEffectBlendingModeWithinWindow; root.state = NSVisualEffectStateActive;
    root.wantsLayer = YES; root.layer.cornerRadius = 18; root.layer.masksToBounds = YES;
    root.layer.borderWidth = 0.5; root.layer.borderColor = NSColor.separatorColor.CGColor;
    panel.contentView = root;
    NSImageView *glass = [[NSImageView alloc] initWithFrame:NSMakeRect(24, (DPMiniHeaderHeight - 16) / 2, 16, 16)];
    glass.identifier = @"DiaMiniSearchIcon";
    glass.image = [NSImage imageWithSystemSymbolName:@"magnifyingglass" accessibilityDescription:nil]; [root addSubview:glass];
    self.search = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 17, width - 104, 30)];
    self.search.bordered = NO; self.search.drawsBackground = NO; self.search.focusRingType = NSFocusRingTypeNone;
    self.search.usesSingleLineMode = YES;
    self.search.placeholderString = @"Search or Enter URL…"; self.search.font = [NSFont systemFontOfSize:16 weight:NSFontWeightSemibold];
    CGFloat textHeight = self.search.fittingSize.height;
    self.search.frame = NSMakeRect(50, (DPMiniHeaderHeight - textHeight) / 2, width - 104, textHeight);
    self.search.delegate = self; self.search.target = self; self.search.action = @selector(choose:);
    self.search.accessibilityIdentifier = @"DiaMiniSearchField"; self.search.accessibilityLabel = @"Search or Enter URL";
    [root addSubview:self.search];
    NSButton *close = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"xmark" accessibilityDescription:@"Close Dia Mini"] target:self action:@selector(dismiss:)];
    close.frame = NSMakeRect(width - 46, 20, 24, 24); close.bordered = NO;
    close.wantsLayer = YES; close.layer.cornerRadius = 6;
    close.layer.backgroundColor = [NSColor.controlColor colorWithAlphaComponent:0.4].CGColor;
    [root addSubview:close];
    NSBox *divider = [[NSBox alloc] initWithFrame:NSMakeRect(10, DPMiniHeaderHeight, width - 20, 1)];
    divider.boxType = NSBoxSeparator; divider.identifier = @"DiaMiniSearchDivider"; [root addSubview:divider];
    self.table = [[DPMiniSuggestionTable alloc] initWithFrame:NSZeroRect]; self.table.headerView = nil;
    self.table.style = NSTableViewStylePlain;
    self.table.backgroundColor = NSColor.clearColor; self.table.rowHeight = DPMiniRowHeight; self.table.intercellSpacing = NSZeroSize;
    self.table.delegate = self; self.table.dataSource = self; self.table.target = self; self.table.action = @selector(choose:);
    self.table.focusRingType = NSFocusRingTypeNone;
    [self.table addTableColumn:[[NSTableColumn alloc] initWithIdentifier:@"suggestion"]];
    self.scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect]; self.scroll.drawsBackground = NO;
    self.scroll.documentView = self.table; self.scroll.hasVerticalScroller = NO; [root addSubview:self.scroll];
    self.status = [NSTextField labelWithString:@"No recent results"];
    self.status.font = [NSFont systemFontOfSize:12]; self.status.textColor = NSColor.secondaryLabelColor;
    [root addSubview:self.status];
    [self resizeForResults];
}
- (void)dismiss:(id)sender { [self close]; }
@end
