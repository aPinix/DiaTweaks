#import "Patches/DiaMini/Browse/BrowserExtensions.h"

@interface DPExtensionFixtureInfo : NSObject
@property(copy, getter=id) NSString *identifier;
@property(copy) NSString *name;
@property(strong) NSImage *icon;
@property BOOL enabled, hasAction;
@end
@implementation DPExtensionFixtureInfo
@end
@interface DPExtensionFixtureService : NSObject
@property(copy) id values;
@property BOOL ready;
@end
@implementation DPExtensionFixtureService
- (BOOL)isExtensionSystemReady { return self.ready; }
- (id)listExtensions { return self.values; }
@end
@interface DPExtensionFixtureContext : NSObject
@property(strong) DPExtensionFixtureService *extensions;
@end
@implementation DPExtensionFixtureContext
@end

static DPExtensionFixtureInfo *DPExtensionInfo(NSString *identifier, NSString *name, BOOL enabled, BOOL action) {
    DPExtensionFixtureInfo *info = [DPExtensionFixtureInfo new]; info.identifier = identifier; info.name = name;
    info.enabled = enabled; info.hasAction = action; return info;
}

void DPTestMiniExtensions(DPBrowseSource *source) {
    BOOL on = DPDiaMini.on; DPDiaMini.on = YES; DPBrowseApply(&DPDiaMini);
    DPBrowseWindow *owner = DPBrowseOpen([NSURL URLWithString:@"https://extension-fixture.example/"],source,NSZeroRect);
    NSCAssert(owner, @"extensions fixture opens its own Mini");
    id originalContext = owner.profileContext;
    DPExtensionFixtureContext *context = [DPExtensionFixtureContext new];
    context.extensions = [DPExtensionFixtureService new]; context.extensions.ready = YES;
    NSString *longName = [@"Long extension title " stringByPaddingToLength:180 withString:@"abcdefghij " startingAtIndex:0];
    context.extensions.values = @[DPExtensionInfo(@"disabled",longName,NO,YES), DPExtensionInfo(@"action",@"Action",YES,YES),
        DPExtensionInfo(@"background",@"Background",YES,NO), DPExtensionInfo(@"action",@"Duplicate",YES,YES), @42];
    owner.profileContext = context;
    DPMiniExtensionCatalog *catalog = DPBrowseMiniExtensionCatalog(owner);
    NSCAssert(catalog.available && catalog.ready && catalog.items.count == 2 && [catalog.items.firstObject.name isEqual:@"Action"],
        @"catalog reads only the Mini profile, sorts names and ignores duplicate or malformed entries");
    NSCAssert([catalog.items[0].status isEqual:@"Open in Dia to use"] && [catalog.items[1].status isEqual:@"No toolbar action"], @"only enabled extensions enter the catalogue");
    context.extensions.values = @[DPExtensionInfo(@"long",longName,YES,YES)];
    DPMiniExtensionList *list = [DPMiniExtensionList new]; list.owner = owner; [list loadView];
    list.search.stringValue = @"LONG EXTENSION"; [list filter:nil];
    NSCAssert(list.filtered.count == 1 && [list.filtered.firstObject.name isEqual:longName], @"extension names search case-insensitively");
    NSView *row = [list tableView:list.table viewForTableColumn:list.table.tableColumns.firstObject row:0];
    NSTextField *name = (id)DPFindView(row,^BOOL(NSView *view) { return [view isKindOfClass:NSTextField.class]
        && [((NSTextField *)view).stringValue isEqual:longName]; });
    NSCAssert(name.usesSingleLineMode && name.maximumNumberOfLines == 1 && name.lineBreakMode == NSLineBreakByTruncatingTail
        && NSContainsRect(row.bounds,name.frame) && [name.toolTip isEqual:longName], @"long names remain one line inside the row with their full tooltip");
    NSCAssert(!list.table.action && !list.table.doubleAction && ![list tableView:list.table shouldSelectRow:0]
        && list.openButton.action == @selector(openInDia:), @"catalog rows never invoke extensions or promote the page; the footer is an explicit action");
    list.search.stringValue = @"no such extension"; [list filter:nil];
    NSCAssert(!list.filtered.count && !list.status.hidden && [list.status.stringValue isEqual:@"No matching extensions."], @"empty search has a visible result state");
    context.extensions.ready = NO; [list reloadCatalog:nil];
    NSCAssert(list.catalog.available && !list.catalog.ready && !list.filtered.count
        && [list.status.stringValue isEqual:@"Extensions are starting…"], @"initializing extension systems do not look like an empty installed catalog");
    context.extensions.ready = YES; context.extensions.values = @[DPExtensionInfo(@"disabled",@"Disabled only",NO,YES)]; [list reloadCatalog:nil];
    NSCAssert(list.catalog.ready && [list.status.stringValue isEqual:@"No enabled extensions in this profile."], @"an empty enabled list has its own state");
    context.extensions.values = @42; [list reloadCatalog:nil];
    NSCAssert(!list.catalog.available && !list.filtered.count, @"malformed native catalog replies are unavailable");
    owner.profileContext = [NSObject new]; [list reloadCatalog:nil];
    NSCAssert(!list.catalog.available && !list.status.hidden && list.status.stringValue.length, @"missing native catalog APIs have a visible fallback");
    owner.profileContext = context; context.extensions.values = @[DPExtensionInfo(@"action",@"Action",YES,YES)];
    NSButton *button = DPBrowseMiniExtensionsButton(owner); button.frame = NSMakeRect(30,30,26,24);
    [owner.window.contentView addSubview:button]; [owner.window makeKeyAndOrderFront:nil];
    NSCAssert(button.action == @selector(showMiniExtensions:) && button.target == owner && NSWidth(button.frame) == 26, @"puzzle button targets only its Mini");
    [owner showMiniExtensions:button];
    NSPopover *popup = DPBrowseMiniExtensionsPopover(owner); DPMiniExtensionList *shown = (id)popup.contentViewController;
    NSCAssert(popup.shown && shown.owner == owner && shown.ownerCloseObserver, @"extension popup is attached to its live Mini");
    DPBrowseCloseMiniExtensions(owner);
    NSCAssert(!popup.shown && !DPBrowseMiniExtensionsPopover(owner) && !shown.ownerCloseObserver, @"explicit dismissal removes popup storage and its owner observer");
    [owner showMiniExtensions:button]; popup = DPBrowseMiniExtensionsPopover(owner); shown = (id)popup.contentViewController;
    owner.profileContext = originalContext; [owner close];
    NSCAssert(!popup.shown && !DPBrowseMiniExtensionsPopover(owner) && !shown.ownerCloseObserver, @"closing Mini also cleans its extension popup");
    DPDiaMini.on = on; DPBrowseApply(&DPDiaMini); [source.window makeKeyAndOrderFront:nil];
}
