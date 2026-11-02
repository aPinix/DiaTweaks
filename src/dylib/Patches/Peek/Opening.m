#import "Patches/Peek/Peek.h"
#import <objc/message.h>

@interface DPPeekLoadingCanvas : NSView
@end
@implementation DPPeekLoadingCanvas
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)dirty { [NSColor.textBackgroundColor setFill]; NSRectFill(dirty); }
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; self.needsDisplay = YES; }
@end

@implementation DPPeekCard (Opening)
- (void)showWhileLoading {
    if (![self.page respondsToSelector:@selector(isReadyToDisplay)]) { [self animateIn]; return; }
    // Paint a temporary page canvas beneath Chromium, so growth is visible even before its first frame.
    // It never covers the live host: page pixels appear as soon as Chromium supplies them.
    NSView *canvas = [[DPPeekLoadingCanvas alloc] initWithFrame:self.clip.bounds];
    canvas.wantsLayer = YES; canvas.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    canvas.identifier = @"DiaPeekLoadingCanvas";
    [self.clip addSubview:canvas positioned:NSWindowBelow relativeTo:self.host]; self.loadingCanvas = canvas;
    [self animateIn];
    __weak DPPeekCard *weak = self;
    self.contentTimer = [NSTimer timerWithTimeInterval:1.0 / 30 repeats:YES block:^(NSTimer *timer) {
        DPPeekCard *peek = weak;
        if (!peek || peek.closing || !peek.window) { [timer invalidate]; peek.contentTimer = nil; return; }
        BOOL (*ready)(id, SEL) = (void *)objc_msgSend;
        NSURL *url = [(NSObject *)peek.page valueForKey:@"url"];
        if (!ready(peek.page, @selector(isReadyToDisplay)) || !DPPeekCanLoad(url)) return;
        [timer invalidate]; peek.contentTimer = nil;
        [peek.loadingCanvas removeFromSuperview]; peek.loadingCanvas = nil;
    }];
    [NSRunLoop.mainRunLoop addTimer:self.contentTimer forMode:NSRunLoopCommonModes];
}
@end
