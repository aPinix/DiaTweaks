#import "BrowserOpenChooserInternal.h"

@implementation DPMiniBrowserDestinations
- (void)loadView {
    CGFloat body = MAX(1, MIN(8, self.catalog.entries.count)) * DPMiniDestinationRowHeight;
    self.view = DPBrowseDestinationSurface(NSMakeRect(0,0,DPMiniDestinationWidth,DPMiniDestinationHeaderHeight+body+DPMiniDestinationBottom));
    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(16,15,14,14)];
    icon.image = [NSImage imageWithSystemSymbolName:@"magnifyingglass" accessibilityDescription:nil];
    icon.contentTintColor = NSColor.secondaryLabelColor; [self.view addSubview:icon];
    NSString *placeholder = [NSString stringWithFormat:@"Search %@…", self.catalog.title ?: @"Destinations"];
    self.search = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.search.bordered = NO; self.search.drawsBackground = NO; self.search.focusRingType = NSFocusRingTypeNone;
    self.search.usesSingleLineMode = YES; self.search.maximumNumberOfLines = 1;
    self.search.cell.wraps = NO; self.search.cell.scrollable = YES;
    self.search.placeholderString = placeholder; self.search.accessibilityLabel = placeholder;
    self.search.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    CGFloat height = self.search.fittingSize.height;
    self.search.frame = NSMakeRect(42,(DPMiniDestinationHeaderHeight-height)/2,162,height);
    self.search.delegate = self; [self.view addSubview:self.search];
    NSBox *divider = [[NSBox alloc] initWithFrame:NSMakeRect(207,12,1,20)];
    divider.boxType = NSBoxSeparator; [self.view addSubview:divider];
    NSButton *up = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.up" accessibilityDescription:@"Close destinations"]
        target:self action:@selector(dismiss:)];
    up.frame = NSMakeRect(214,10,24,24); up.bordered = NO; up.contentTintColor = NSColor.secondaryLabelColor;
    up.accessibilityLabel = @"Close destinations"; [self.view addSubview:up];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,DPMiniDestinationHeaderHeight,DPMiniDestinationWidth,body)];
    scroll.drawsBackground = NO; scroll.hasVerticalScroller = YES; scroll.scrollerStyle = NSScrollerStyleOverlay;
    self.table = DPBrowseDestinationTable(); self.table.frame = scroll.bounds;
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"destination"];
    column.width = DPMiniDestinationWidth; [self.table addTableColumn:column];
    self.table.dataSource = self; self.table.delegate = self; self.table.target = self;
    self.table.action = self.table.doubleAction = @selector(choose:);
    self.table.accessibilityLabel = [NSString stringWithFormat:@"Open in Dia %@", self.catalog.title ?: @"destinations"];
    scroll.documentView = self.table; [self.view addSubview:scroll];
    self.status = [NSTextField labelWithString:@"No matching destinations"];
    self.status.font = [NSFont systemFontOfSize:12]; self.status.textColor = NSColor.secondaryLabelColor;
    self.status.alignment = NSTextAlignmentCenter; self.status.frame = NSMakeRect(8,DPMiniDestinationHeaderHeight+14,DPMiniDestinationWidth-16,20);
    [self.view addSubview:self.status]; [self filter:nil];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView { return self.filtered.count; }
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    return DPBrowseDestinationCell(self.filtered[row]);
}
- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row { return DPBrowseDestinationRow(); }
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row { return DPBrowseDestinationAvailable(self.filtered[row]); }
- (void)controlTextDidChange:(NSNotification *)note { [self filter:nil]; }
- (void)filter:(id)sender {
    NSString *query = self.search.stringValue;
    self.filtered = [self.catalog.entries filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DPMiniNativeDestination *choice, NSDictionary *bindings) {
        return !query.length || [choice.title localizedCaseInsensitiveContainsString:query]
            || [choice.groupTitle localizedCaseInsensitiveContainsString:query];
    }]];
    [self.table reloadData]; NSInteger selected = -1;
    for (NSUInteger row = 0; row < self.filtered.count; row++) if (DPBrowseDestinationAvailable(self.filtered[row])) {
        if (selected < 0) selected = row;
        if (self.filtered[row].state == NSControlStateValueOn) { selected = row; break; }
    }
    if (selected >= 0) [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
    else [self.table deselectAll:nil];
    self.status.stringValue = self.catalog.entries.count ? @"No matching destinations" : @"No destinations available";
    self.status.hidden = self.filtered.count > 0;
    self.table.accessibilityHelp = self.filtered.count ? @"Return keeps this page in the selected destination" : self.status.stringValue;
}
- (void)choose:(id)sender {
    NSInteger row = self.table.selectedRow;
    if (row < 0 || row >= (NSInteger)self.filtered.count || !DPBrowseDestinationAvailable(self.filtered[row])) return (void)NSBeep();
    DPMiniNativeDestination *choice = self.filtered[row];
    [self.owner.destinationPopover close]; [self.owner openNativeDestination:choice];
}
- (void)dismiss:(id)sender { [self.owner.destinationPopover close]; }
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    if (selector == @selector(insertNewline:)) { [self choose:nil]; return YES; }
    if (selector == @selector(cancelOperation:)) { [self dismiss:nil]; return YES; }
    NSInteger step = selector == @selector(moveDown:) ? 1 : selector == @selector(moveUp:) ? -1 : 0;
    if (!step || !self.filtered.count) return NO;
    NSInteger row = self.table.selectedRow;
    do { row += step; } while (row >= 0 && row < (NSInteger)self.filtered.count && !DPBrowseDestinationAvailable(self.filtered[row]));
    if (row >= 0 && row < (NSInteger)self.filtered.count) {
        [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO]; [self.table scrollRowToVisible:row];
    }
    return YES;
}
@end
