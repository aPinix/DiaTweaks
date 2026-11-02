#import "BrowserDestinationsInternal.h"

@implementation DPMiniNativeDestination
@end
@implementation DPMiniNativeDestinations
@end

NSString *DPBrowseDestinationItemIdentifier(NSMenuItem *item) {
    if (!item) return nil;
    NSString *key = item.identifier;
    // Dia 1.56 uses the selector as the identifier for unrelated callback items.
    if (!key.length || [key isEqual:NSStringFromSelector(item.action)]) return nil;
    return key;
}
NSString *DPBrowseDestinationRepresentedIdentity(NSMenuItem *item) {
    id value = item.representedObject;
    if ([value isKindOfClass:NSString.class]) return [@"string:" stringByAppendingString:value];
    if ([value isKindOfClass:NSUUID.class]) return [@"uuid:" stringByAppendingString:[value UUIDString]];
    if ([value isKindOfClass:NSNumber.class]) return [@"number:" stringByAppendingString:[value stringValue]];
    // Never parse a private Swift value's description or retain its captured action context.
    return nil;
}
DPMiniNativeDestinations *DPBrowseDiscoverNativeDestinations(NSMenu *menu, BOOL refresh) {
    DPMiniDestinationMenu *scope = DPBrowseFindDestinationMenu(menu, refresh);
    if (!scope) return nil;
    DPMiniNativeDestinations *catalog = [DPMiniNativeDestinations new]; catalog.kind = scope.kind;
    catalog.title = scope.kind == DPMiniNativeDestinationSpace ? @"Spaces" : @"Profiles";
    NSMutableArray *entries = [NSMutableArray array];
    for (DPMiniDestinationMenuRow *row in DPBrowseDestinationMenuRows(scope)) {
        DPMiniNativeDestination *entry = [DPMiniNativeDestination new];
        entry.title = row.display.title; entry.groupTitle = row.group;
        entry.nativeIdentifier = DPBrowseDestinationItemIdentifier(row.move);
        entry.representedIdentity = DPBrowseDestinationRepresentedIdentity(row.move ?: row.display);
        entry.image = [row.display.image copy]; entry.state = row.display.state;
        entry.enabled = row.display.enabled; entry.hasNativeMoveAction = row.move != nil;
        entry.kind = scope.kind; [entries addObject:entry];
    }
    NSCountedSet *identifiers = [NSCountedSet new];
    for (DPMiniNativeDestination *entry in entries) if (entry.nativeIdentifier.length) [identifiers addObject:entry.nativeIdentifier];
    for (DPMiniNativeDestination *entry in entries) {
        if (entry.nativeIdentifier.length && [identifiers countForObject:entry.nativeIdentifier] > 1) entry.nativeIdentifier = nil;
    }
    catalog.entries = entries; return catalog;
}
