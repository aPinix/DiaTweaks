#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, DPMiniNativeDestinationKind) {
    DPMiniNativeDestinationSpace,
    DPMiniNativeDestinationProfile,
};

// Display metadata only. No pre-adoption menu target or callback is retained.
@interface DPMiniNativeDestination : NSObject
@property(readonly, copy) NSString *title, *groupTitle, *nativeIdentifier;
@property(readonly, strong) NSImage *image;
@property(readonly) NSControlStateValue state;
@property(readonly) BOOL enabled;
@property(readonly) BOOL hasNativeMoveAction;
@property(readonly) DPMiniNativeDestinationKind kind;
@end

@interface DPMiniNativeDestinations : NSObject
@property(readonly, copy) NSString *title;
@property(readonly, copy) NSArray<DPMiniNativeDestination *> *entries;
@property(readonly) DPMiniNativeDestinationKind kind;
@end

// Discovers real native Space-move menus, or honestly labeled Profile destinations.
DPMiniNativeDestinations *DPBrowseDiscoverNativeDestinations(NSMenu *menu, BOOL refresh);
// Resolves only a fresh native move action, never a profile-switch action.
NSMenuItem *DPBrowseResolveNativeDestination(NSMenu *menu, DPMiniNativeDestination *choice);
// Call only after adoption. The guard must prove the selected live page is the adopted Mini.
BOOL DPBrowseInvokeNativeDestination(NSMenu *menu, DPMiniNativeDestination *choice, BOOL (^expectedPageIsSelected)(void));
// Describes a context event to the selected tab's native menu builder; never dispatches mouse input.
NSMenu *DPBrowseMenuForSelectedNativeTab(NSWindow *window, BOOL (^expectedPageIsSelected)(void));
