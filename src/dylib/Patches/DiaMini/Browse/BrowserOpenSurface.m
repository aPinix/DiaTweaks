#import "BrowserOpenChooserInternal.h"

@interface DPMiniDestinationSurface : NSVisualEffectView
@property(strong) NSView *tint;
@end
@interface DPMiniDestinationTint : NSView
@end
@implementation DPMiniDestinationTint
- (NSView *)hitTest:(NSPoint)point { return nil; }
@end
@implementation DPMiniDestinationSurface
- (BOOL)isFlipped { return YES; }
- (void)updateColors {
    BOOL dark = [[self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua,NSAppearanceNameDarkAqua]] isEqual:NSAppearanceNameDarkAqua];
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.tint.layer.backgroundColor = (dark ? [NSColor colorWithSRGBRed:0.03 green:0.025 blue:0.12 alpha:0.84]
            : [NSColor.windowBackgroundColor colorWithAlphaComponent:0.82]).CGColor;
        self.layer.borderColor = [NSColor.labelColor colorWithAlphaComponent:0.14].CGColor;
        self.layer.borderWidth = 1 / MAX(1,self.window.backingScaleFactor);
    }];
}
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; [self updateColors]; }
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self updateColors]; }
- (void)viewDidChangeBackingProperties { [super viewDidChangeBackingProperties]; [self updateColors]; }
@end
NSView *DPBrowseDestinationSurface(NSRect frame) {
    DPMiniDestinationSurface *surface = [[DPMiniDestinationSurface alloc] initWithFrame:frame];
    surface.material = NSVisualEffectMaterialPopover; surface.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    surface.state = NSVisualEffectStateActive; surface.wantsLayer = YES;
    surface.layer.cornerRadius = 12; surface.layer.masksToBounds = YES;
    surface.tint = [[DPMiniDestinationTint alloc] initWithFrame:surface.bounds]; surface.tint.wantsLayer = YES;
    surface.tint.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; [surface addSubview:surface.tint];
    surface.identifier = @"DiaMiniDestinationPicker"; return surface;
}

@interface DPMiniDestinationRow : NSTableRowView
@property(strong) NSTrackingArea *hover;
@end
@implementation DPMiniDestinationRow
- (void)updateTrackingAreas {
    [super updateTrackingAreas]; if (self.hover) [self removeTrackingArea:self.hover];
    self.hover = [[NSTrackingArea alloc] initWithRect:NSZeroRect
        options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:self.hover];
}
- (void)mouseEntered:(NSEvent *)event {
    NSTableView *table = [self.superview isKindOfClass:NSTableView.class] ? (id)self.superview : nil;
    NSInteger row = [table rowForView:self];
    if (row >= 0 && [table.delegate tableView:table shouldSelectRow:row])
        [table selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [[NSColor.selectedContentBackgroundColor colorWithAlphaComponent:0.22] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds,3,0) xRadius:4 yRadius:4] fill];
}
@end
NSTableRowView *DPBrowseDestinationRow(void) { return [DPMiniDestinationRow new]; }
NSView *DPBrowseDestinationCell(DPMiniNativeDestination *choice) {
    NSView *cell = [[NSView alloc] initWithFrame:NSMakeRect(0,0,DPMiniDestinationWidth,DPMiniDestinationRowHeight)];
    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(10,10,26,26)];
    icon.image = choice.image ?: [NSImage imageWithSystemSymbolName:choice.kind == DPMiniNativeDestinationSpace ? @"rectangle.stack" : @"person.crop.square" accessibilityDescription:nil];
    icon.imageScaling = NSImageScaleProportionallyUpOrDown;
    if (!choice.image) icon.contentTintColor = NSColor.secondaryLabelColor;
    [cell addSubview:icon];
    NSTextField *label = [NSTextField labelWithString:choice.title ?: @""];
    label.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold]; label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.textColor = DPBrowseDestinationAvailable(choice) ? NSColor.labelColor : NSColor.disabledControlTextColor;
    label.frame = NSMakeRect(46,(DPMiniDestinationRowHeight-label.fittingSize.height)/2,DPMiniDestinationWidth-58,label.fittingSize.height);
    [cell addSubview:label]; cell.toolTip = choice.groupTitle.length ? [NSString stringWithFormat:@"%@: %@",choice.groupTitle,choice.title] : choice.title;
    cell.accessibilityLabel = choice.title; return cell;
}
@interface DPMiniDestinationTable : NSTableView
@end
@implementation DPMiniDestinationTable
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (void)keyDown:(NSEvent *)event {
    if (event.keyCode == 53) [NSApp sendAction:@selector(dismiss:) to:self.target from:self];
    else if (event.keyCode == 36 || event.keyCode == 76) [NSApp sendAction:self.action to:self.target from:self];
    else [super keyDown:event];
}
@end
NSTableView *DPBrowseDestinationTable(void) {
    NSTableView *table = [DPMiniDestinationTable new]; table.headerView = nil; table.style = NSTableViewStylePlain;
    table.backgroundColor = NSColor.clearColor; table.rowHeight = DPMiniDestinationRowHeight;
    table.intercellSpacing = NSZeroSize; table.focusRingType = NSFocusRingTypeNone; return table;
}
