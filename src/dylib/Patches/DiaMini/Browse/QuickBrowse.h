#import "StdPatch/StdPatch.h"

// Arc's Objective-C navigation policy values, verified on Dia 1.56.
enum { DPBrowseCancel = 0, DPBrowseCurrentTab = 1, DPBrowseForegroundTab = 2, DPBrowseNewWindow = 5 };

// Only Objective-C entry points; no Chromium C++ layouts or Swift offsets.
@protocol DPBrowseContents <NSObject>
@property(readonly) NSView *nativeView;
@property(readonly) NSURL *url;
@property(readonly) NSString *title;
@property(readonly) id navigationController;
@property(readonly) BOOL canGoBack, canGoForward;
@property BOOL hasFocus;
@property NSInteger visibility;
- (NSView *)createPaneHostView;
- (void)attachToPaneHostView:(NSView *)view;
- (void)detachFromPaneHostView:(NSView *)view;
- (void)setUIDelegate:(id)delegate;
- (void)close;
@end

@interface DPBrowseSource : NSObject
@property(strong) id browser;
@property(weak) id contents, delegate;
@property(weak) id browserDelegate;
@property(weak) NSWindow *window;
@end

@interface DPBrowseWindow : NSWindowController <NSWindowDelegate, NSTextFieldDelegate>
@property(strong) DPBrowseSource *source;
@property(strong) id<DPBrowseContents> contents;
@property(strong) id contentsDelegate;
@property(strong) NSView *host;
@property(strong) NSTextField *address;
@property(strong) NSButton *backButton, *forwardButton;
@property(strong) NSTimer *refresh;
@property BOOL closing, transferred;
@property NSRect launcherFrame;
@property (strong) NSRunningApplication *returnApplication;
- (BOOL)startWithURL:(NSURL *)url source:(DPBrowseSource *)source;
@end

@interface DPBrowseWindow (Chrome)
- (void)buildChrome;
- (void)updatePage;
@end
@interface DPBrowseWindow (Navigation)
- (void)promote:(id)sender;
- (void)navigate:(id)sender;
- (void)back:(id)sender;
- (void)forward:(id)sender;
- (void)reload:(id)sender;
@end

extern DPPatch DPDiaMini, DPDiaMiniExternal;
extern NSMutableSet<DPBrowseWindow *> *DPBrowseWindows;
extern NSMenuItem *DPNewMiniItem;
void DPInstallQuickBrowse(void);
BOOL DPBrowseCompatible(void);
BOOL DPBrowseShow(NSURL *url, DPBrowseSource *source);
DPBrowseWindow *DPBrowseOpen(NSURL *url, DPBrowseSource *source, NSRect launcherFrame);
DPBrowseSource *DPBrowseSourceFor(id contents);
DPBrowseSource *DPBrowseFrontSource(void);
BOOL DPBrowseSourceUsable(DPBrowseSource *source);
NSView *DPBrowseHost(id contents);
id DPBrowseDelegate(id contents);
void DPBrowseApply(DPPatch *patch);
NSString *DPBrowseVerify(DPPatch *patch);
void DPBrowseInstallTracking(void);
void DPBrowseInstallEvents(void);
void DPBrowseInstallDelegateHooks(Class cls);
void DPBrowseInstallCallbacks(void);
void DPBrowseInstallExternal(void);
void DPBrowseRememberDelegate(id contents, id delegate);
NSURL *DPBrowseURL(id value);
NSURL *DPBrowseAddress(NSString *text);
NSRect DPBrowseFrame(NSRect parent, NSRect screen);
NSRect DPBrowseLauncherFrame(NSRect screen, CGFloat height);
void DPBrowsePrepareSource(void);
void DPBrowseReleaseSource(void);
void DPBrowseInstallBrowsers(void);
void DPBrowseRememberBrowser(id browser, id delegate, NSWindow *window);
NSWindow *DPBrowseWindowForBrowser(id browser);
DPBrowseSource *DPBrowseFallbackSource(NSWindow *window);
NSArray *DPBrowseKnownBrowsers(void);
NSArray *DPBrowseKnownContents(void);
id DPBrowseBrowserDelegate(id browser);
