#import "BrowserDestinationsInternal.h"

@implementation DPMiniDestinationMenu
@end
@implementation DPMiniDestinationMenuRow
@end

static NSString *DPMiniMenuTitle(NSString *title) {
    return [[[(title ?: @"") stringByReplacingOccurrencesOfString:@"…" withString:@""]
        stringByReplacingOccurrencesOfString:@"..." withString:@""] lowercaseString];
}
static BOOL DPMiniManagementItem(NSMenuItem *item) {
    NSString *title = DPMiniMenuTitle(item.title), *key = item.identifier ?: @"";
    return [@[@"new profile", @"manage profiles", @"new space", @"manage spaces", @"profile settings"] containsObject:title]
        || [@[@"newSpaceMenuItem", @"appSpacesMenuChangeToNewProfile"] containsObject:key];
}
static void DPMiniRefreshMenu(NSMenu *menu) {
    id<NSMenuDelegate> delegate = menu.delegate;
    if ([delegate respondsToSelector:@selector(menuNeedsUpdate:)]) [delegate menuNeedsUpdate:menu];
    [menu update];
}
static void DPMiniFindMenus(NSMenu *menu, BOOL refresh, NSMutableArray *found, NSUInteger depth) {
    if (!menu || depth > 8) return;
    if (refresh) DPMiniRefreshMenu(menu);
    for (NSMenuItem *item in menu.itemArray) {
        if (!item.submenu || item.hidden) continue;
        NSString *title = DPMiniMenuTitle(item.title), *key = item.identifier ?: @"";
        DPMiniDestinationMenu *scope = nil;
        BOOL space = [@[@"move to space", @"move to spaces"] containsObject:title]
            || [@[@"moveToSpaceTabContextMenuOption", @"moveToSpace"] containsObject:key];
        BOOL profile = [title isEqual:@"move to profile"] || [key isEqual:@"moveToProfile"];
        if (space || profile) {
            scope = [DPMiniDestinationMenu new]; scope.menu = item.submenu;
            scope.kind = space ? DPMiniNativeDestinationSpace : DPMiniNativeDestinationProfile;
            scope.priority = space ? 3 : 2;
        } else {
            BOOL managesProfiles = NO;
            for (NSMenuItem *child in item.submenu.itemArray) {
                managesProfiles |= [DPMiniMenuTitle(child.title) isEqual:@"new profile"];
            }
            if (managesProfiles) {
                scope = [DPMiniDestinationMenu new]; scope.menu = item.submenu;
                scope.kind = DPMiniNativeDestinationProfile;
                scope.mode = DPMiniDestinationProfileSwitcher; scope.priority = 1;
            }
        }
        if (scope) { scope.container = item; if (refresh) DPMiniRefreshMenu(scope.menu); [found addObject:scope]; }
        DPMiniFindMenus(item.submenu, refresh, found, depth + 1);
    }
}
DPMiniDestinationMenu *DPBrowseFindDestinationMenu(NSMenu *menu, BOOL refresh) {
    NSMutableArray<DPMiniDestinationMenu *> *found = [NSMutableArray array];
    DPMiniFindMenus(menu, refresh, found, 0);
    [found sortUsingComparator:^NSComparisonResult(DPMiniDestinationMenu *a, DPMiniDestinationMenu *b) {
        return a.priority > b.priority ? NSOrderedAscending : a.priority < b.priority ? NSOrderedDescending : NSOrderedSame;
    }];
    for (DPMiniDestinationMenu *scope in found) if (DPBrowseDestinationMenuRows(scope).count) return scope;
    return nil;
}
static void DPMiniAppendRows(NSMenu *menu, DPMiniDestinationMenuMode mode, NSString *group, NSMutableArray *rows, NSUInteger depth) {
    if (depth > 6) return;
    for (NSMenuItem *item in menu.itemArray) {
        if (item.separatorItem || item.hidden || !item.title.length || DPMiniManagementItem(item)) continue;
        if (item.submenu) {
            DPMiniAppendRows(item.submenu, mode, group.length ? [group stringByAppendingFormat:@" / %@", item.title] : item.title, rows, depth + 1);
            continue;
        }
        if (!item.action || item.alternate) continue;
        DPMiniDestinationMenuRow *row = [DPMiniDestinationMenuRow new]; row.display = item; row.group = group;
        if (mode == DPMiniDestinationMoveMenu) row.move = item;
        // A same-named hidden or Option variant is not proof of a move action.
        [rows addObject:row];
    }
}
NSArray<DPMiniDestinationMenuRow *> *DPBrowseDestinationMenuRows(DPMiniDestinationMenu *scope) {
    NSMutableArray *rows = [NSMutableArray array]; if (scope) DPMiniAppendRows(scope.menu, scope.mode, @"", rows, 0); return rows;
}
