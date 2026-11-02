#import "Patches/Peek/Peek.h"

static NSView *DPLayerView(void) {
    NSView *view = [NSView new];
    view.wantsLayer = YES;
    return view;
}

// Escape or ⌘W closes it, as in Arc, and ⌘O opens it as a tab. Escape reaches a field being edited first, so it can
// cancel the edit there. Key codes: O 31, W 13, Escape 53.
static id DPWatchKeys(DPPeekCard *card) {
    __weak DPPeekCard *weak = card;
    return [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
        DPPeekCard *peek = weak;
        if (!peek || event.window != peek.window) return event;
        NSEventModifierFlags mods = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask & ~NSEventModifierFlagCapsLock;
        BOOL command = mods == NSEventModifierFlagCommand, editing = [peek.window.firstResponder isKindOfClass:NSText.class];
        if (command && event.keyCode == 31) [peek close:1];
        else if ((command && event.keyCode == 13) || (!mods && event.keyCode == 53 && !editing)) [peek close:0];
        else return event;
        return nil;
    }];
}

DPPeekCard *DPPeekShowCard(NSWindow *window, id<DPPeekPage> page, NSPoint origin) {
    NSView *host = [page createPaneHostView], *pane = nil;
    if (!window || !host || DPPeekCardIn(window)) return nil;
    for (NSView *candidate in DPFindViews(DPDiaContentPane))
        if (candidate.window == window && NSWidth(candidate.bounds) * NSHeight(candidate.bounds) > NSWidth(pane.bounds) * NSHeight(pane.bounds)) pane = candidate;
    NSView *surface = pane;
    for (NSView *view = pane; view; view = view.superview)
        if (DPIsKind(view, DPDiaContentContainer)) { surface = view; break; }
    if (!surface.superview) return nil;
    DPPeekCard *peek = [[DPPeekCard alloc] initWithFrame:surface.frame];
    peek.wantsLayer = YES;
    peek.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    peek.pane = pane;
    peek.surface = surface;
    peek.page = page;
    peek.clickPointInWindow = [window convertPointFromScreen:origin];
    peek.host = host;
    peek.card = DPLayerView();
    peek.card.layer.shadowOpacity = 0.35;
    peek.card.layer.shadowRadius = 24;
    peek.card.layer.shadowOffset = CGSizeMake(0, -6);
    peek.clip = DPLayerView();
    // Chromium paints its own background. An opaque backing can bleed through its rounded edge.
    peek.clip.layer.backgroundColor = NSColor.clearColor.CGColor;
    peek.clip.layer.cornerRadius = 10;
    peek.clip.layer.cornerCurve = kCACornerCurveContinuous;
    peek.clip.layer.masksToBounds = YES;
    peek.controls = DPPeekControls(peek, @selector(control:));
    [peek.clip addSubview:host];
    [peek.card addSubview:peek.clip];
    for (NSView *view in @[peek.card, peek.controls]) [peek addSubview:view];
    // Insert immediately above the content frame, preserving the sidebar's higher native stacking order.
    [surface.superview addSubview:peek positioned:NSWindowAbove relativeTo:surface];
    [peek layoutSubtreeIfNeeded];
    [page attachToPaneHostView:host];
    [window makeFirstResponder:host];
    if (surface) {
        surface.postsFrameChangedNotifications = YES;
        __weak DPPeekCard *weak = peek;
        peek.paneObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSViewFrameDidChangeNotification object:surface queue:nil
                                                                        usingBlock:^(NSNotification *note) { [weak followPane]; }];
    }
    peek.monitor = DPWatchKeys(peek);
    [peek animateIn];
    return peek;
}
