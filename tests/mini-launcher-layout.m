#import "Patches/DiaMini/Browse/Launcher.h"

void DPTestMiniLauncherLayout(DPMiniLauncher *launcher) {
    NSArray *saved = launcher.suggestions;
    NSString *text = launcher.search.stringValue;
    NSPoint topRight = NSMakePoint(NSMaxX(launcher.window.frame), NSMaxY(launcher.window.frame));
    NSView *root = launcher.window.contentView;
    NSView *glass = DPFindView(root, ^BOOL(NSView *view) { return [view.identifier isEqual:@"DiaMiniSearchIcon"]; });
    NSView *divider = DPFindView(root, ^BOOL(NSView *view) { return [view.identifier isEqual:@"DiaMiniSearchDivider"]; });
    NSCAssert(glass && divider && fabs(NSMidY(glass.frame) - NSMidY(launcher.search.frame)) < 0.5,
        @"the search field is vertically centered with its header icon");
    NSCAssert(launcher.search.usesSingleLineMode && launcher.search.maximumNumberOfLines == 1
        && !launcher.search.cell.wraps && launcher.search.cell.scrollable, @"long URLs use one horizontally scrolling line");
    NSCAssert(NSMinY(divider.frame) > NSMaxY(launcher.search.frame)
        && NSMaxY(divider.frame) <= NSMinY(launcher.scroll.frame), @"a divider separates the header from its results");
    NSMutableArray *many = [NSMutableArray new];
    NSTextView *editor = [NSTextView new];
    for (NSUInteger i = 0; i < 8; i++) {
        DPBrowseSuggestion *item = [DPBrowseSuggestion new];
        item.url = [NSURL URLWithString:[NSString stringWithFormat:@"https://result.example/%lu", i]];
        item.title = [NSString stringWithFormat:@"Result %lu", i]; [many addObject:item];
    }
    for (NSString *query in @[@"", @"result"]) {
        launcher.search.stringValue = query; [launcher setResults:many];
        NSCAssert(launcher.suggestions.count == 5 && launcher.table.numberOfRows == 5, @"recents and searches offer five choices");
        NSCAssert(launcher.status.hidden && !launcher.scroll.hidden, @"results have no bottom hint row");
        NSCAssert(NSContainsRect(launcher.table.visibleRect, [launcher.table rectOfRow:4]),
            @"all five choices fit without scrolling (visible=%@ row=%@ scroll=%@ panel=%@ root=%@ loaded=%d)",
            NSStringFromRect(launcher.table.visibleRect), NSStringFromRect([launcher.table rectOfRow:4]),
            NSStringFromRect(launcher.scroll.frame), NSStringFromRect(launcher.window.frame), NSStringFromRect(root.bounds), launcher.isWindowLoaded);
        for (NSUInteger i = 0; i < 8; i++)
            [launcher control:launcher.search textView:editor doCommandBySelector:@selector(moveDown:)];
        NSCAssert(launcher.table.selectedRow == 4, @"keyboard selection cannot reach a hidden sixth result");
        for (NSUInteger i = 0; i < 8; i++)
            [launcher control:launcher.search textView:editor doCommandBySelector:@selector(moveUp:)];
        NSCAssert(launcher.table.selectedRow == 0, @"upward navigation stops at the first choice");
        NSCAssert(NSMaxX(launcher.window.frame) == topRight.x && NSMaxY(launcher.window.frame) == topRight.y,
            @"the visible panel keeps its top-right anchor as the list grows");
    }
    NSWindow *shadow = launcher.shadowWindow;
    NSCAssert(shadow.visible && shadow.ignoresMouseEvents && !shadow.canBecomeKeyWindow
        && [launcher.window.childWindows containsObject:shadow], @"the larger shadow follows its panel without taking input or focus");
    NSCAssert(NSContainsRect(shadow.frame, launcher.window.frame) && NSWidth(shadow.frame) > NSWidth(launcher.window.frame) + 64,
        @"the shadow has room outside the panel's bounds");
    NSCAssert(fabs(NSMidX(shadow.frame) - NSMidX(launcher.window.frame)) < 0.5
        && fabs(NSMidY(shadow.frame) - NSMidY(launcher.window.frame)) < 0.5,
        @"the menu bar does not displace the shadow from its panel");
    launcher.search.stringValue = @""; [launcher setResults:@[]];
    NSCAssert(!launcher.status.hidden && launcher.scroll.hidden && NSContainsRect(root.bounds, launcher.status.frame),
        @"empty-state messages occupy the list area");
    launcher.search.stringValue = text; [launcher setResults:saved];
    NSTextView *nativeEditor = (id)launcher.search.currentEditor;
    NSCAssert([nativeEditor isKindOfClass:NSTextView.class], @"the real field editor is available for long-URL layout");
    launcher.updatingInput = YES;
    NSString *longURL = [@"https://www.google.com/search?q=" stringByAppendingString:[@"long-query-" stringByPaddingToLength:1200 withString:@"long-query-" startingAtIndex:0]];
    launcher.search.stringValue = nativeEditor.string = longURL;
    [nativeEditor.layoutManager ensureLayoutForTextContainer:nativeEditor.textContainer];
    __block NSUInteger lines = 0;
    [nativeEditor.layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0,nativeEditor.layoutManager.numberOfGlyphs)
        usingBlock:^(NSRect rect, NSRect used, NSTextContainer *container, NSRange glyphs, BOOL *stop) { lines++; }];
    NSCAssert(lines == 1, @"a long selected Google URL cannot wrap into a clipped second line");
    launcher.search.stringValue = nativeEditor.string = text; launcher.updatingInput = NO;
}
