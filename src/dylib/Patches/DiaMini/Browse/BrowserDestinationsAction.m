#import "BrowserDestinationsInternal.h"

NSMenuItem *DPBrowseResolveNativeDestination(NSMenu *menu, DPMiniNativeDestination *choice) {
    if (!choice) return nil;
    DPMiniDestinationMenu *scope = DPBrowseFindDestinationMenu(menu, YES);
    if (!scope || !scope.container.enabled || scope.kind != choice.kind) return nil;
    NSMutableArray<NSMenuItem *> *matches = [NSMutableArray array];
    for (DPMiniDestinationMenuRow *row in DPBrowseDestinationMenuRows(scope)) {
        if (!row.move) continue;
        BOOL same = choice.nativeIdentifier.length
            ? [choice.nativeIdentifier isEqual:DPBrowseDestinationItemIdentifier(row.move)]
            : choice.representedIdentity.length ? [choice.representedIdentity isEqual:DPBrowseDestinationRepresentedIdentity(row.move)]
            : [choice.title isEqual:row.display.title] && [choice.groupTitle isEqual:row.group];
        if (same) [matches addObject:row.move];
    }
    if (matches.count != 1) return nil;
    NSMenuItem *item = matches.firstObject;
    return item.enabled && !item.hidden && item.action && item.target ? item : nil;
}
BOOL DPBrowseInvokeNativeDestination(NSMenu *menu, DPMiniNativeDestination *choice, BOOL (^expectedPageIsSelected)(void)) {
    if (!expectedPageIsSelected || !expectedPageIsSelected()) return NO;
    NSMenuItem *item = DPBrowseResolveNativeDestination(menu, choice);
    if (!item || !expectedPageIsSelected()) return NO;
    @try { return [NSApp sendAction:item.action to:item.target from:item]; }
    @catch (NSException *exception) { return NO; }
}
