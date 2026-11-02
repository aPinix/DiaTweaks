#import "Patches/DiaMini/Browse/Launcher.h"
#import "Patches/DiaMini/Shortcuts/Shortcut.h"

extern DPPatch DPCommandBar;
extern NSMenuItem *DPCommandBarItem;
extern NSNotificationName const DPCommandBarShortcutDidChangeNotification;

@interface DPCommandBarShortcut : DPMiniShortcut
@end
@interface DPCommandBarRecorder : DPMiniShortcutRecorder
@end
@interface DPCommandBarLauncher : DPMiniLauncher
@property (weak) NSWindow *observedSource;
@property (strong) id sourceResizeObserver, sourceCloseObserver;
@end
@interface DPCommandBarLauncher (Placement)
- (void)trackSourceWindow;
- (NSRect)launcherFrameForHeight:(CGFloat)height;
@end

void DPCommandBarShow(void);
void DPCommandBarClose(void);
void DPCommandBarInstallKeyboard(void);
void DPCommandBarInstallSettings(void);
void DPCommandBarUpdateBinding(void);
void DPCommandBarRestoreBindings(void);
void DPCommandBarPauseShortcut(BOOL paused);
BOOL DPCommandBarShortcutPaused(void);
BOOL DPCommandBarHandleEvent(NSEvent *event);
BOOL DPCommandBarSaveShortcut(DPMiniShortcut *shortcut, BOOL reset, NSString **error);
NSString *DPCommandBarShortcutConflict(DPMiniShortcut *shortcut, NSMenu *menu);
NSString *DPCommandBarMiniShortcutConflict(DPMiniShortcut *shortcut);
NSString *DPCommandBarShortcutError(void);
BOOL DPCommandBarIsAdopting(void);
void DPCommandBarOpenTab(DPCommandBarLauncher *launcher, NSURL *url, void (^completion)(BOOL));
