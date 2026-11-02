#import "BrowserExtensions.h"

@implementation DPMiniExtensionList
- (void)loadView {
    self.view = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0,0,320,374)];
    ((NSVisualEffectView *)self.view).material = NSVisualEffectMaterialMenu;
    NSTextField *title = [NSTextField labelWithString:@"Extensions"]; title.frame = NSMakeRect(14,342,250,18);
    title.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold]; [self.view addSubview:title];
    NSButton *reload = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"arrow.clockwise" accessibilityDescription:@"Refresh extensions"] target:self action:@selector(reloadCatalog:)];
    reload.bordered = NO; reload.frame = NSMakeRect(282,338,26,26); reload.toolTip = @"Refresh extensions"; [self.view addSubview:reload];
    self.search = [[NSSearchField alloc] initWithFrame:NSMakeRect(12,302,296,28)];
    self.search.placeholderString = @"Search extensions…"; self.search.accessibilityLabel = @"Search extensions";
    self.search.delegate = self; self.search.target = self; self.search.action = @selector(filter:);
    self.search.sendsSearchStringImmediately = YES; [self.view addSubview:self.search];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(8,74,304,220)];
    scroll.drawsBackground = NO; scroll.hasVerticalScroller = YES; scroll.autohidesScrollers = YES;
    self.table = [[NSTableView alloc] initWithFrame:scroll.bounds];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"extension"]; column.width = 302;
    [self.table addTableColumn:column]; self.table.headerView = nil; self.table.rowHeight = 44;
    self.table.dataSource = self; self.table.delegate = self; self.table.backgroundColor = NSColor.clearColor;
    self.table.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone; self.table.accessibilityLabel = @"Installed extensions in this profile";
    scroll.documentView = self.table; [self.view addSubview:scroll];
    self.status = [NSTextField wrappingLabelWithString:@""]; self.status.frame = NSMakeRect(18,164,280,60);
    self.status.alignment = NSTextAlignmentCenter; self.status.font = [NSFont systemFontOfSize:12]; self.status.textColor = NSColor.secondaryLabelColor;
    [self.view addSubview:self.status];
    NSBox *divider = [[NSBox alloc] initWithFrame:NSMakeRect(12,64,296,1)]; divider.boxType = NSBoxSeparator; [self.view addSubview:divider];
    NSTextField *hint = [NSTextField labelWithString:@"Open this page in Dia to use extensions."];
    hint.frame = NSMakeRect(14,42,294,16); hint.font = [NSFont systemFontOfSize:11]; hint.textColor = NSColor.secondaryLabelColor; [self.view addSubview:hint];
    self.openButton = [NSButton buttonWithTitle:@"Open in Dia" target:self action:@selector(openInDia:)];
    self.openButton.frame = NSMakeRect(202,6,108,28); [self.view addSubview:self.openButton];
    [self reloadCatalog:nil];
}
- (void)reloadCatalog:(id)sender { self.catalog = DPBrowseMiniExtensionCatalog(self.owner); [self filter:nil]; }
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table { return self.filtered.count; }
- (BOOL)tableView:(NSTableView *)table shouldSelectRow:(NSInteger)row { return NO; }
- (NSView *)tableView:(NSTableView *)table viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    DPMiniExtensionItem *item = self.filtered[row]; NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,column.width,44)];
    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(10,12,20,20)];
    icon.image = item.icon ?: [NSImage imageWithSystemSymbolName:@"puzzlepiece.extension" accessibilityDescription:nil];
    icon.imageScaling = NSImageScaleProportionallyDown; icon.alphaValue = item.enabled ? 1 : 0.45; [view addSubview:icon];
    NSTextField *name = [NSTextField labelWithString:item.name]; name.frame = NSMakeRect(40,22,MAX(1,column.width-50),17);
    name.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium]; name.usesSingleLineMode = YES;
    name.maximumNumberOfLines = 1; name.lineBreakMode = NSLineBreakByTruncatingTail; name.toolTip = item.name;
    name.textColor = item.enabled ? NSColor.labelColor : NSColor.secondaryLabelColor; [view addSubview:name];
    NSTextField *detail = [NSTextField labelWithString:item.status]; detail.frame = NSMakeRect(40,5,MAX(1,column.width-50),15);
    detail.font = [NSFont systemFontOfSize:10]; detail.textColor = NSColor.secondaryLabelColor; [view addSubview:detail];
    return view;
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
- (void)controlTextDidChange:(NSNotification *)note { [self filter:nil]; }
- (BOOL)control:(NSControl *)control textView:(NSTextView *)view doCommandBySelector:(SEL)selector {
    if (selector != @selector(cancelOperation:)) return NO;
    DPBrowseCloseMiniExtensions(self.owner); return YES;
}
- (void)openInDia:(id)sender {
    DPBrowseWindow *owner = self.owner;
    DPBrowseCloseMiniExtensions(owner); [owner promote:nil];
}
- (void)dealloc { [self stopWatchingOwner]; }
@end
