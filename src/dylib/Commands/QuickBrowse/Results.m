#import "Launcher.h"
#import <objc/message.h>

@interface DPMiniResultRow : NSTableRowView
@end
@implementation DPMiniResultRow
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [NSColor.controlAccentColor setFill];
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 0, 2) xRadius:6 yRadius:6] fill];
}
@end

@implementation DPMiniLauncher (ResultsData)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table { return self.suggestions.count; }
- (NSTableRowView *)tableView:(NSTableView *)table rowViewForRow:(NSInteger)row { return [DPMiniResultRow new]; }
- (NSView *)tableView:(NSTableView *)table viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    DPBrowseSuggestion *item = self.suggestions[row];
    NSTableCellView *cell = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, column.width, 50)];
    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(12, 16, 18, 18)];
    icon.image = item.icon ?: [NSImage imageWithSystemSymbolName:@"globe" accessibilityDescription:nil];
    [cell addSubview:icon]; cell.imageView = icon;
    NSTextField *label = [NSTextField labelWithString:@""];
    [cell addSubview:label]; cell.textField = label;
    cell.textField.frame = NSMakeRect(42, 15, MAX(1, column.width - 52), 20);
    cell.textField.lineBreakMode = NSLineBreakByTruncatingTail;
    BOOL selected = table.selectedRow == row;
    NSDictionary *title = @{NSFontAttributeName:[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName:selected ? NSColor.whiteColor : NSColor.labelColor};
    NSDictionary *url = @{NSFontAttributeName:[NSFont systemFontOfSize:12 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName:selected ? [NSColor.whiteColor colorWithAlphaComponent:0.6] : NSColor.secondaryLabelColor};
    NSMutableAttributedString *line = [[NSMutableAttributedString alloc] initWithString:item.title ?: item.url.host attributes:title];
    [line appendAttributedString:[[NSAttributedString alloc] initWithString:[@" — " stringByAppendingString:item.url.host ?: @""] attributes:url]];
    cell.textField.attributedStringValue = line;
    return cell;
}
- (void)tableViewSelectionDidChange:(NSNotification *)note {
    if (self.suggestions.count) [self.table reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.suggestions.count)]
        columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}
- (void)setResults:(NSArray<DPBrowseSuggestion *> *)results {
    NSInteger selected = self.table.selectedRow;
    NSURL *previous = selected >= 0 && selected < (NSInteger)self.suggestions.count ? self.suggestions[selected].url : nil;
    NSUInteger limit = self.search.stringValue.length ? 6 : 4;
    self.suggestions = [results subarrayWithRange:NSMakeRange(0, MIN(limit,results.count))];
    [self.table reloadData];
    selected = 0;
    for (NSUInteger i=0;i<self.suggestions.count;i++) if ([self.suggestions[i].url isEqual:previous]) selected=i;
    if (self.suggestions.count) [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
    self.hint.stringValue = self.suggestions.count ? @"↵ Open    ·    esc Close" : @"Recent results from this profile";
    [self resizeForResults];
    id context = DPBrowseContext(self.source);
    if (![context respondsToSelector:@selector(favicon:completion:)]) return;
    __weak DPMiniLauncher *weak = self;
    for (DPBrowseSuggestion *item in self.suggestions) {
        if (item.iconRequested) continue;
        item.iconRequested = YES;
        void (*favicon)(id,SEL,NSURL *,void (^)(id)) = (void *)objc_msgSend;
        favicon(context,@selector(favicon:completion:),item.url,^(id icon) {
            if (![icon isKindOfClass:NSImage.class]) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                DPMiniLauncher *launcher=weak;
                if (![launcher.suggestions containsObject:item]) return;
                item.icon=icon;
                NSUInteger index=[launcher.suggestions indexOfObjectIdenticalTo:item];
                if (index!=NSNotFound) [launcher.table reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
                    columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            });
        });
    }
}
@end
