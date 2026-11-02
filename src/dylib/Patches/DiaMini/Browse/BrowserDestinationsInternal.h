#import "BrowserDestinations.h"

typedef NS_ENUM(NSInteger, DPMiniDestinationMenuMode) {
    DPMiniDestinationMoveMenu,
    DPMiniDestinationProfileSwitcher,
};
@interface DPMiniNativeDestination ()
@property(readwrite, copy) NSString *title, *groupTitle, *nativeIdentifier;
@property(readwrite, strong) NSImage *image;
@property(readwrite) NSControlStateValue state;
@property(readwrite) BOOL enabled;
@property(readwrite) BOOL hasNativeMoveAction;
@property(readwrite) DPMiniNativeDestinationKind kind;
@property(copy) NSString *representedIdentity;
@end
@interface DPMiniNativeDestinations ()
@property(readwrite, copy) NSString *title;
@property(readwrite, copy) NSArray<DPMiniNativeDestination *> *entries;
@property(readwrite) DPMiniNativeDestinationKind kind;
@end

@interface DPMiniDestinationMenu : NSObject
@property(strong) NSMenu *menu;
@property(strong) NSMenuItem *container;
@property DPMiniNativeDestinationKind kind;
@property DPMiniDestinationMenuMode mode;
@property NSInteger priority;
@end
@interface DPMiniDestinationMenuRow : NSObject
@property(strong) NSMenuItem *display, *move;
@property(copy) NSString *group;
@end
DPMiniDestinationMenu *DPBrowseFindDestinationMenu(NSMenu *menu, BOOL refresh);
NSArray<DPMiniDestinationMenuRow *> *DPBrowseDestinationMenuRows(DPMiniDestinationMenu *scope);
NSString *DPBrowseDestinationItemIdentifier(NSMenuItem *item);
NSString *DPBrowseDestinationRepresentedIdentity(NSMenuItem *item);
