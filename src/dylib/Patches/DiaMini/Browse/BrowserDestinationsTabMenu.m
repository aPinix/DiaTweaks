#import "BrowserDestinations.h"
#import "QuickBrowse.h"

static BOOL DPMiniTabSelected(id object, NSUInteger depth) {
    if (!object || depth > 6) return NO;
    id<NSAccessibility> element = object;
    NSString *role = [object respondsToSelector:@selector(accessibilityRole)] ? element.accessibilityRole : nil;
    NSString *identifier = [object respondsToSelector:@selector(accessibilityIdentifier)] ? element.accessibilityIdentifier : nil;
    BOOL tab = DPIsKind(object, DPDiaTabView) || [identifier isEqual:@"tab"]
        || [role isEqual:@"AXTab"] || [role isEqual:NSAccessibilityRadioButtonRole];
    id value = [object respondsToSelector:@selector(accessibilityValue)] ? element.accessibilityValue : nil;
    if (tab && [value isKindOfClass:NSNumber.class] && [value boolValue]) return YES;
    if (tab && [value isKindOfClass:NSString.class] && [value isEqual:@"on"]) return YES;
    NSArray *children = [object respondsToSelector:@selector(accessibilityChildren)] ? element.accessibilityChildren : nil;
    for (id child in children) if (DPMiniTabSelected(child, depth + 1)) return YES;
    return NO;
}

NSMenu *DPBrowseMenuForSelectedNativeTab(NSWindow *window, BOOL (^expectedPageIsSelected)(void)) {
    if (!window.visible || !expectedPageIsSelected || !expectedPageIsSelected()) return nil;
    NSMutableArray<NSView *> *selected = [NSMutableArray array];
    for (NSView *row in DPFindViews(DPDiaTabView)) {
        if (row.window == window && !row.hiddenOrHasHiddenAncestor && row.alphaValue > 0 && !NSIsEmptyRect(row.bounds)
            && DPMiniTabSelected(row, 0)) [selected addObject:row];
    }
    if (selected.count != 1 || !expectedPageIsSelected()) return nil;
    NSView *row = selected.firstObject;
    NSPoint point = [row convertPoint:NSMakePoint(NSMidX(row.bounds), NSMidY(row.bounds)) toView:nil];
    NSEvent *description = [NSEvent mouseEventWithType:NSEventTypeRightMouseDown location:point modifierFlags:0
        timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:window.windowNumber context:nil
        eventNumber:0 clickCount:1 pressure:0];
    NSMenu *menu = nil;
    @try { menu = [row menuForEvent:description]; }
    @catch (NSException *exception) { return nil; }
    return expectedPageIsSelected() ? menu : nil;
}
