#import "Patches/CommandBar/CommandBar.h"

void DPTestCommandBarShortcuts(void);
void DPTestCommandBarRecorder(void);
void DPTestCommandBarTabs(void);
void DPTestCommandBarOpenTabs(DPBrowseSource *source);

@interface DPCommandBrowserProxy : NSProxy
@property (strong) id target;
@end
@implementation DPCommandBrowserProxy
- (BOOL)respondsToSelector:(SEL)selector {
    return class_getInstanceMethod(object_getClass(self), selector) || [self.target respondsToSelector:selector];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector { return [self.target methodSignatureForSelector:selector]; }
- (void)forwardInvocation:(NSInvocation *)invocation { [invocation invokeWithTarget:self.target]; }
@end

static void DPTestCommandModeSwitch(DPBrowseSource *source, DPMiniLauncher *mini) {
    DPCommandBrowserProxy *proxy = [DPCommandBrowserProxy alloc]; proxy.target = source.browser;
    DPBrowseSource *captured = [DPBrowseSource new];
    captured.browser = proxy; captured.contents = source.contents; captured.delegate = source.delegate;
    captured.browserDelegate = source.browserDelegate; captured.window = source.window;
    NSCAssert(DPBrowseSourceUsable(captured) && DPBrowseFrontSource().browser != proxy,
        @"the palette's distinct browser identity cannot be rediscovered from the native tab");
    mini.source = captured;
    DPCommandBarShow(); DPMiniLauncher *command = DPCurrentMiniLauncher;
    NSCAssert(command && command.commandBar && command != mini && !mini.window.visible
        && command.source.browser == proxy, @"switching Mini to Command Bar captures its source before closing Mini");
    DPBrowseShowLauncher(); DPMiniLauncher *replacement = DPCurrentMiniLauncher;
    NSCAssert(replacement && !replacement.commandBar && replacement != command && !command.window.visible
        && replacement.source.browser == proxy, @"switching Command Bar to Mini keeps the captured source and closes the old palette");
    [replacement close];
}

void DPTestCommandBar(DPBrowseSource *source) {
    DPTestCommandBarShortcuts(); DPTestCommandBarRecorder(); DPTestCommandBarTabs(); DPTestCommandBarOpenTabs(source);
    BOOL commandOn = DPCommandBar.on, miniOn = DPDiaMini.on;
    DPPatch *patch = &DPCommandBar; patch->on = YES; patch->apply(patch);
    DPDiaMini.on = NO; DPBrowseApply(&DPDiaMini);
    DPCommandBarLauncher *bar = [DPCommandBarLauncher new]; bar.commandBar = YES; bar.source = source;
    DPCurrentMiniLauncher = bar; [bar show];
    NSCAssert(bar.window.visible && bar.launcherEnabled && [bar.window.identifier isEqual:@"DiaTweaks.CommandBar"],
        @"Command Bar opens while Mini is disabled");
    NSRect content = [source.window convertRectToScreen:[source.window.contentView convertRect:source.window.contentView.bounds toView:nil]];
    NSCAssert(fabs(NSMidX(bar.window.frame) - NSMidX(content)) < 1 && NSWidth(bar.window.frame) <= 764,
        @"the bar centers in the source window and fits its width");
    NSRect small = [bar launcherFrameForHeight:130], large = [bar launcherFrameForHeight:330];
    NSCAssert(fabs(NSMaxY(small) - NSMaxY(large)) < 1, @"the bar keeps its top edge while results grow");
    DPBrowseCloseLauncher(); NSCAssert(bar.window.visible, @"turning Mini off leaves Command Bar open");
    patch->on = NO; patch->apply(patch);
    NSCAssert(!bar.window.visible && !DPCurrentMiniLauncher, @"turning Command Bar off closes its bar and shared shadow");
    DPDiaMini.on = YES; DPBrowseApply(&DPDiaMini); DPBrowseShowLauncher();
    DPMiniLauncher *mini = DPCurrentMiniLauncher; DPCommandBarClose();
    NSCAssert(mini && !mini.commandBar && mini.window.visible, @"closing a disabled Command Bar leaves Mini open");
    patch->on = YES; patch->apply(patch); DPTestCommandModeSwitch(source, mini);
    patch->on = commandOn; patch->apply(patch); DPDiaMini.on = miniOn; DPBrowseApply(&DPDiaMini);
    [source.window makeKeyAndOrderFront:nil];
}
