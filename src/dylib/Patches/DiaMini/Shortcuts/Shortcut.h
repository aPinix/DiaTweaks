#import "../Browse/Launcher.h"
#import <Carbon/Carbon.h>

@interface DPMiniShortcut : NSObject
@property (readonly) UInt32 keyCode;
@property (readonly) NSEventModifierFlags modifiers;
@property (copy, readonly) NSString *characters;
+ (instancetype)defaultShortcut;
+ (instancetype)current;
+ (instancetype)fromEvent:(NSEvent *)event;
- (instancetype)initWithCode:(UInt32)code modifiers:(NSEventModifierFlags)modifiers characters:(NSString *)characters;
- (BOOL)sameKey:(DPMiniShortcut *)other;
- (NSString *)label;
- (UInt32)carbonModifiers;
- (NSDictionary *)dictionary;
@end

extern NSNotificationName const DPMiniShortcutDidChangeNotification;
NSUserDefaults *DPMiniShortcutDefaults(void);
BOOL DPMiniSaveShortcut(DPMiniShortcut *shortcut, BOOL reset, NSString **error);
NSString *DPMiniShortcutMenuConflict(DPMiniShortcut *shortcut, NSMenu *menu);
NSString *DPBrowseHotkeyError(void);
void DPBrowsePauseHotkey(BOOL paused);
BOOL DPBrowseHotkeyPaused(void);
void DPBrowseInstallShortcutSettings(void);

@interface DPMiniShortcutRecorder : NSButton
@property BOOL recording;
@property (strong) DPMiniShortcut *pending;
@property (weak) NSTextField *hint;
@property (strong) id monitor, windowObserver, shortcutObserver;
@property (copy) NSString *message;
- (void)startRecording;
- (void)stopRecording;
- (void)resetShortcut:(id)sender;
- (void)refresh;
@end
@interface DPMiniShortcutRecorder (Events)
- (BOOL)consumeEvent:(NSEvent *)event;
@end
