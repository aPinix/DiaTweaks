#import "Launcher.h"

@class DPMiniShortcut;

@interface DPMiniWindowCommand : DPMiniLauncher
@property (weak) DPBrowseWindow *miniOwner;
@property (strong) NSView *miniScrim;
@property (strong) id miniResizeObserver, miniCloseObserver, outsideMouseMonitor;
@end
@interface DPMiniWindowCommand (Placement)
- (void)watchMiniOwner;
- (void)stopWatchingMini;
- (NSRect)launcherFrameForHeight:(CGFloat)height;
- (void)resizeForResults;
@end
@interface DPMiniWindowCommand (Backdrop)
- (void)installMiniScrim;
- (void)removeMiniScrim;
@end
@interface DPMiniWindowCommand (Input)
- (void)prefillMiniAddress;
@end

DPBrowseWindow *DPBrowseMiniForWindow(NSWindow *window);
void DPBrowseEditMini(DPBrowseWindow *owner, BOOL prefill);
BOOL DPBrowseLoadMini(DPBrowseWindow *owner, NSURL *url);
BOOL DPBrowseHandleMiniKeyEvent(NSEvent *event);
NSString *DPBrowseReservedMiniShortcut(DPMiniShortcut *shortcut);
