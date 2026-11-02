#import "Patches/DiaMini/Browse/BrowserDestinations.h"

@interface DPDestinationFixtureAction : NSObject
@property NSUInteger calls;
- (void)perform:(id)sender;
@end
@implementation DPDestinationFixtureAction
- (void)perform:(id)sender { self.calls++; }
@end
static NSMenuItem *DPDestinationItem(NSString *title, DPDestinationFixtureAction *action) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(perform:) keyEquivalent:@""];
    item.target = action; item.identifier = @"perform:"; return item;
}
static NSMenuItem *DPDestinationRoot(NSMenu *menu, NSString *title) {
    NSMenuItem *root = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    root.submenu = [NSMenu new]; root.submenu.autoenablesItems = NO; [menu addItem:root]; return root;
}
void DPTestMiniDestinations(void) {
    NSMenu *main = [NSMenu new]; main.autoenablesItems = NO;
    DPDestinationFixtureAction *switchAction = [DPDestinationFixtureAction new], *moveAction = [DPDestinationFixtureAction new];
    NSMenu *profiles = DPDestinationRoot(main, @"Personal").submenu;
    NSMenuItem *personal = DPDestinationItem(@"Personal", switchAction); personal.state = NSControlStateValueOn;
    personal.image = [NSImage imageWithSystemSymbolName:@"person.crop.square" accessibilityDescription:nil];
    [profiles addItem:personal]; [profiles addItem:DPDestinationItem(@"Work", switchAction)];
    [profiles addItem:DPDestinationItem(@"New Profile…", switchAction)]; [profiles addItem:DPDestinationItem(@"Manage Profiles…", switchAction)];
    DPMiniNativeDestinations *catalog = DPBrowseDiscoverNativeDestinations(main, NO);
    NSCAssert(catalog.kind == DPMiniNativeDestinationProfile && [catalog.title isEqual:@"Profiles"] && catalog.entries.count == 2,
        @"native profile destinations are labeled honestly and omit management commands");
    DPMiniNativeDestination *choice = catalog.entries.lastObject;
    NSCAssert([catalog.entries.firstObject.title isEqual:@"Personal"] && catalog.entries.firstObject.image
        && catalog.entries.firstObject.state == NSControlStateValueOn && !choice.nativeIdentifier,
        @"snapshot preserves native names, colors and current check without treating generic selectors as identities");
    NSCAssert(!DPBrowseResolveNativeDestination(main, choice), @"a profile-switch callback is never replayed as a move");
    NSMenu *moves = DPDestinationRoot(main, @"Move to Profile").submenu;
    NSMenuItem *oldMove = DPDestinationItem(@"Work", moveAction); [moves addItem:oldMove];
    [moves removeItem:oldMove]; DPDestinationFixtureAction *fresh = [DPDestinationFixtureAction new];
    NSMenuItem *freshMove = DPDestinationItem(@"Work", fresh); [moves addItem:freshMove];
    NSCAssert(DPBrowseResolveNativeDestination(main, choice) == freshMove, @"post-adoption resolution uses the new move callback");
    NSCAssert(!DPBrowseInvokeNativeDestination(main, choice, ^BOOL{ return NO; }) && fresh.calls == 0 && switchAction.calls == 0,
        @"an unrelated selected page cannot receive the move action");
    __block NSUInteger checks = 0;
    NSCAssert(!DPBrowseInvokeNativeDestination(main, choice, ^BOOL{ return ++checks == 1; }) && fresh.calls == 0,
        @"a selection change during menu refresh cancels dispatch");
    NSCAssert(DPBrowseInvokeNativeDestination(main, choice, ^BOOL{ return YES; }) && fresh.calls == 1
        && moveAction.calls == 0 && switchAction.calls == 0, @"only the fresh explicitly named move action runs");
    freshMove.enabled = NO;
    NSCAssert(!DPBrowseResolveNativeDestination(main, choice), @"native disabled destinations remain unavailable"); freshMove.enabled = YES;
    [moves addItem:DPDestinationItem(@"Work", moveAction)];
    NSCAssert(!DPBrowseResolveNativeDestination(main, choice), @"ambiguous fallback names never choose an arbitrary profile");
    NSMenu *spaces = DPDestinationRoot(main, @"Move to Space").submenu;
    NSMenuItem *dev = DPDestinationItem(@"Dev", moveAction); dev.identifier = @"space:dev-uuid"; [spaces addItem:dev];
    catalog = DPBrowseDiscoverNativeDestinations(main, NO); choice = catalog.entries.firstObject;
    NSCAssert(catalog.kind == DPMiniNativeDestinationSpace && [catalog.title isEqual:@"Spaces"]
        && [choice.nativeIdentifier isEqual:@"space:dev-uuid"], @"real native Space movement takes precedence and keeps its identifier");
    dev.title = @"Renamed Dev";
    NSCAssert(DPBrowseResolveNativeDestination(main, choice) == dev, @"stable Space identity survives a display-name change");
    dev.identifier = @"space:replacement-uuid";
    NSCAssert(!DPBrowseResolveNativeDestination(main, choice), @"a deleted Space cannot be replaced by a same-named destination");
    NSMenu *replica = [NSMenu new]; NSMenu *nativeProfiles = DPDestinationRoot(replica, @"Personal").submenu;
    NSMenuItem *primary = DPDestinationItem(@"Personal", switchAction); primary.state = NSControlStateValueOn; [nativeProfiles addItem:primary];
    NSMenuItem *hidden = DPDestinationItem(@"Personal", moveAction); hidden.hidden = YES; [nativeProfiles addItem:hidden];
    [nativeProfiles addItem:DPDestinationItem(@"New Profile…", switchAction)];
    catalog = DPBrowseDiscoverNativeDestinations(replica, NO); choice = catalog.entries.firstObject;
    NSCAssert(catalog.entries.count == 1 && choice.state == NSControlStateValueOn && !choice.hasNativeMoveAction
        && !DPBrowseResolveNativeDestination(replica, choice), @"hidden native duplicates are never guessed to be move actions");
}
