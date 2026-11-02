#import "../Search/Provider.h"
#import "WindowCommand.h"

@implementation DPMiniLauncher (Presentation)
- (void)show {
    self.previousApplication = NSWorkspace.sharedWorkspace.frontmostApplication;
    self.restorePrevious = YES;
    self.source = self.source ?: DPBrowseFrontSource();
    self.suggestions = @[];
    [self buildLauncher]; [self focus]; [self query];
    if (self.source) return;
    self.startingSource = YES; self.status.stringValue = @"Starting Dia…";
    DPBrowsePrepareSource();
    __weak DPMiniLauncher *weak = self;
    __block NSUInteger polls = 0;
    self.sourceTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
        DPMiniLauncher *launcher = weak;
        if (!launcher) { [timer invalidate]; return; }
        launcher.source = DPBrowseFrontSource();
        if (!launcher.source && ++polls < 100) return;
        [timer invalidate]; launcher.sourceTimer = nil; launcher.startingSource = NO;
        if (launcher.source) { [launcher.window makeKeyAndOrderFront:nil]; [launcher query]; }
        else launcher.status.stringValue = @"Open a Dia window to use its profile";
    }];
}
@end

void DPBrowseShowLauncher(void) {
    if (!DPDiaMini.on) return;
    if (DPCurrentMiniLauncher && !DPCurrentMiniLauncher.commandBar && ![DPCurrentMiniLauncher isKindOfClass:DPMiniWindowCommand.class]) {
        [DPCurrentMiniLauncher focus]; [DPCurrentMiniLauncher.search selectText:nil]; return;
    }
    DPMiniLauncher *previous = DPCurrentMiniLauncher, *launcher = [DPMiniLauncher new];
    launcher.source = DPBrowseSourceUsable(previous.source) ? previous.source : DPBrowseFrontSource();
    DPCurrentMiniLauncher = launcher;
    previous.restorePrevious = NO; [previous close]; [launcher show];
}
void DPBrowseCloseLauncher(void) { if (!DPCurrentMiniLauncher.commandBar) [DPCurrentMiniLauncher close]; }
