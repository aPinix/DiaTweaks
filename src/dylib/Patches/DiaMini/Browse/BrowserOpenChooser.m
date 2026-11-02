#import "BrowserToolbar.h"

@implementation DPMiniBrowserDestinations
- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,320,274)];
    self.search = [[NSSearchField alloc] initWithFrame:NSMakeRect(12,234,296,28)];
    self.search.placeholderString = @"Search Dia windows"; self.search.accessibilityLabel = @"Search Dia windows";
    self.search.target = self; self.search.action = @selector(filter:); self.search.delegate = self;
    self.search.sendsSearchStringImmediately = YES; [self.view addSubview:self.search];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(8,8,304,218)];
    scroll.hasVerticalScroller = YES; scroll.drawsBackground = NO;
    self.table = [[NSTableView alloc] initWithFrame:scroll.bounds];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"window"]; column.width = 300;
    [self.table addTableColumn:column]; self.table.headerView = nil; self.table.rowHeight = 36;
    self.table.dataSource = self; self.table.delegate = self; self.table.target = self;
    self.table.action = self.table.doubleAction = @selector(choose:); self.table.backgroundColor = NSColor.clearColor;
    self.table.accessibilityLabel = @"Open in Dia destination windows";
    scroll.documentView = self.table; [self.view addSubview:scroll]; [self filter:nil];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView { return self.filtered.count; }
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    DPBrowseSource *source = self.filtered[row];
    NSString *title = source.window.title.length ? source.window.title : @"Dia window";
    NSTextField *label = [NSTextField labelWithString:[NSString stringWithFormat:@"%@  %@", source.window == self.owner.source.window ? @"✓" : @"  ", title]];
    label.font = [NSFont systemFontOfSize:12]; label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.toolTip = title; return label;
}
- (void)filter:(id)sender {
    NSString *query = self.search.stringValue;
    self.filtered = [self.sources filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DPBrowseSource *source, NSDictionary *bindings) {
        NSString *title = source.window.title.length ? source.window.title : @"Dia window";
        return !query.length || [title localizedCaseInsensitiveContainsString:query];
    }]];
    [self.table reloadData];
    if (self.filtered.count) [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    else [self.table deselectAll:nil];
    self.table.accessibilityHelp = self.filtered.count ? @"Return opens this page in the selected window" : @"No matching Dia windows";
}
- (void)choose:(id)sender {
    NSInteger row = self.table.selectedRow;
    if (row < 0 || row >= (NSInteger)self.filtered.count) return (void)NSBeep();
    [self.owner.destinationPopover close]; [self.owner promoteToSource:self.filtered[row]];
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    if (selector == @selector(insertNewline:)) { [self choose:nil]; return YES; }
    if (selector == @selector(cancelOperation:)) { [self.owner.destinationPopover close]; return YES; }
    NSInteger step = selector == @selector(moveDown:) ? 1 : selector == @selector(moveUp:) ? -1 : 0;
    if (!step || !self.filtered.count) return NO;
    NSInteger row = MAX(0, MIN((NSInteger)self.filtered.count-1, self.table.selectedRow+step));
    [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO]; [self.table scrollRowToVisible:row]; return YES;
}
@end
