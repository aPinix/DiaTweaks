#import "Shortcut.h"

static __weak DPMiniShortcutRecorder *DPRecordingShortcut;

@implementation DPMiniShortcutRecorder
- (instancetype)initWithFrame:(NSRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.bezelStyle = NSBezelStyleRounded;
    self.font = [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightMedium];
    self.accessibilityLabel = @"Dia Mini keyboard shortcut";
    self.target = self; self.action = @selector(startRecording);
    self.toolTip = @"Click to record a shortcut. Escape cancels.";
    __weak DPMiniShortcutRecorder *weak = self;
    self.shortcutObserver = [NSNotificationCenter.defaultCenter addObserverForName:self.shortcutNotificationName object:nil queue:nil
        usingBlock:^(NSNotification *note) { [weak refresh]; }];
    [self refresh];
    return self;
}
- (BOOL)acceptsFirstResponder { return YES; }
- (void)refresh {
    self.title = self.recording ? @"Press shortcut…" : self.currentShortcut.label;
    self.accessibilityValue = self.title;
    self.enabled = !self.shortcutUnavailable;
    self.hint.stringValue = self.message ?: (self.recording ? @"Press a shortcut. Escape cancels." : self.shortcutRegistrationError ?: @"Click to change. Include Command, Control or Option.");
    self.hint.textColor = self.message ? NSColor.systemRedColor : NSColor.secondaryLabelColor;
}
- (void)startRecording {
    if (!self.window) return;
    [DPRecordingShortcut stopRecording];
    DPRecordingShortcut = self; self.recording = YES; self.message = nil;
    [self pauseShortcut:YES];
    [self.window makeFirstResponder:self];
    __weak DPMiniShortcutRecorder *weak = self;
    self.monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown | NSEventMaskKeyUp | NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown
        handler:^NSEvent *(NSEvent *event) { return [weak consumeEvent:event] ? nil : event; }];
    self.windowObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowDidResignKeyNotification object:self.window queue:nil
        usingBlock:^(NSNotification *note) { [weak stopRecording]; }];
    [self refresh];
}
- (void)stopRecording {
    if (!self.recording) return;
    self.recording = NO; self.pending = nil; self.message = nil;
    if (self.monitor) [NSEvent removeMonitor:self.monitor];
    if (self.windowObserver) [NSNotificationCenter.defaultCenter removeObserver:self.windowObserver];
    self.monitor = self.windowObserver = nil;
    DPRecordingShortcut = nil;
    [self pauseShortcut:NO];
    [self refresh];
}
- (void)resetShortcut:(id)sender {
    [self stopRecording];
    NSString *error = nil;
    [self saveShortcut:self.defaultShortcut reset:YES error:&error];
    self.message = error; [self refresh];
}
- (void)viewDidMoveToWindow { [super viewDidMoveToWindow]; if (!self.window) [self stopRecording]; }
- (void)dealloc {
    if (self.monitor) [NSEvent removeMonitor:self.monitor];
    for (id observer in @[self.windowObserver ?: NSNull.null, self.shortcutObserver ?: NSNull.null])
        if (observer != NSNull.null) [NSNotificationCenter.defaultCenter removeObserver:observer];
    if (self.recording) [self pauseShortcut:NO];
}
@end
