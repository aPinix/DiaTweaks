#import "BrowserToolbar.h"
#import "BrowserDestinations.h"
#import "BrowserExtensions.h"

static char DPMiniDestinationsKey;
@implementation DPBrowseWindow (OpenDestinations)
- (void)captureNativeDestinations {
    NSWindow *window = self.source.window;
    // Read metadata from the selected native tab, without retaining its callback or changing its selection.
    NSMenu *menu = DPBrowseMenuForSelectedNativeTab(window, ^{ return window.visible; });
    DPMiniNativeDestinations *catalog = DPBrowseDiscoverNativeDestinations(menu, YES);
    if (!catalog.entries.count) catalog = DPBrowseDiscoverNativeDestinations(NSApp.mainMenu, YES);
    objc_setAssociatedObject(self, &DPMiniDestinationsKey, catalog, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (DPMiniNativeDestinations *)nativeDestinations {
    return objc_getAssociatedObject(self, &DPMiniDestinationsKey);
}
- (void)showOpenDestinations:(id)sender {
    if (self.closing || self.promoting || self.transferred) return;
    DPBrowseCloseMiniExtensions(self);
    if (self.destinationPopover.shown) return [self.destinationPopover close];
    [self captureNativeDestinations];
    DPMiniBrowserDestinations *controller = [DPMiniBrowserDestinations new];
    controller.owner = self; controller.catalog = self.nativeDestinations;
    self.destinationPopover = [[DPMiniBrowserDestinationPicker alloc] initWithContentViewController:controller];
    [self.destinationPopover showRelativeToView:self.openControl];
}
@end
