#import "BrowserExtensions.h"

@implementation DPMiniExtensionList
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,250,320)];
    self.view.wantsLayer = YES; self.view.layer.cornerRadius = 10; self.view.layer.masksToBounds = YES;
    self.view.layer.backgroundColor = [NSColor colorWithSRGBRed:0.025 green:0.025 blue:0.12 alpha:0.97].CGColor;
    // Keep the filter model for catalogue refreshes; the compact menu contains only icon/name rows.
    self.search = [NSSearchField new];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,6,250,308)];
    scroll.drawsBackground = NO; scroll.hasVerticalScroller = YES; scroll.autohidesScrollers = YES;
    scroll.scrollerStyle = NSScrollerStyleOverlay;
    self.table = [[NSTableView alloc] initWithFrame:scroll.bounds];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"extension"]; column.width = 246;
    [self.table addTableColumn:column]; self.table.headerView = nil; self.table.rowHeight = 40;
    self.table.intercellSpacing = NSZeroSize;
    self.table.dataSource = self; self.table.delegate = self; self.table.backgroundColor = NSColor.clearColor;
    self.table.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    self.table.accessibilityLabel = @"Installed extensions in this profile";
    scroll.documentView = self.table; [self.view addSubview:scroll];
    self.status = [NSTextField wrappingLabelWithString:@""]; self.status.frame = NSMakeRect(14,130,222,60);
    self.status.alignment = NSTextAlignmentCenter; self.status.font = [NSFont systemFontOfSize:12];
    self.status.textColor = NSColor.whiteColor; [self.view addSubview:self.status];
    self.openButton = [NSButton buttonWithTitle:@"Open in Dia" target:self action:@selector(openInDia:)];
    [self reloadCatalog:nil];
}
- (void)reloadCatalog:(id)sender { self.catalog = DPBrowseMiniExtensionCatalog(self.owner); [self filter:nil]; }
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table { return self.filtered.count; }
- (BOOL)tableView:(NSTableView *)table shouldSelectRow:(NSInteger)row { return NO; }
- (NSView *)tableView:(NSTableView *)table viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    DPMiniExtensionItem *item = self.filtered[row]; NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,column.width,40)];
    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(12,9,22,22)];
    icon.image = item.icon ?: [NSImage imageWithSystemSymbolName:@"puzzlepiece.extension" accessibilityDescription:nil];
    icon.imageScaling = NSImageScaleProportionallyDown; icon.alphaValue = item.enabled ? 1 : 0.45; [view addSubview:icon];
    NSTextField *name = [NSTextField labelWithString:item.name]; name.frame = NSMakeRect(44,12,MAX(1,column.width-54),17);
    name.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold]; name.usesSingleLineMode = YES;
    name.maximumNumberOfLines = 1; name.lineBreakMode = NSLineBreakByTruncatingTail; name.toolTip = item.name;
    name.textColor = [NSColor.whiteColor colorWithAlphaComponent:item.enabled ? 1 : 0.45]; [view addSubview:name];
    view.toolTip = [NSString stringWithFormat:@"%@ — %@",item.name,item.status];
    view.accessibilityHelp = item.status; return view;
}
- (void)filter:(id)sender {
    NSString *query = self.search.stringValue;
    self.filtered = [self.catalog.items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DPMiniExtensionItem *item, NSDictionary *bindings) {
        return !query.length || [item.name localizedCaseInsensitiveContainsString:query];
    }]];
    [self.table reloadData]; self.status.hidden = self.filtered.count != 0;
    self.status.stringValue = self.filtered.count ? @"" : self.catalog.items.count ? @"No matching extensions." : self.catalog.message;
    self.openButton.enabled = [self.owner canPromoteToSource:self.owner.source];
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)view doCommandBySelector:(SEL)selector {
    if (selector != @selector(cancelOperation:)) return NO;
    DPBrowseCloseMiniExtensions(self.owner); return YES;
}
- (void)openInDia:(id)sender { DPBrowseWindow *owner = self.owner; DPBrowseCloseMiniExtensions(owner); [owner promote:nil]; }
- (void)dealloc { [self stopWatchingOwner]; }
@end
