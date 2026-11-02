#import "Patches/Peek/Indicator.h"

static id<NSAccessibility> DPSelected(id object, NSHashTable *seen, NSUInteger depth) {
    if (!object || depth > 20 || [seen containsObject:object] || seen.count > 5000) return nil;
    if (DPIsKind(object, DPDiaContentPane) || [object isKindOfClass:DPPeekCard.class]) return nil;
    [seen addObject:object];
    id<NSAccessibility> element = object;
    NSString *identifier = [object respondsToSelector:@selector(accessibilityIdentifier)] ? element.accessibilityIdentifier : nil;
    NSString *role = [object respondsToSelector:@selector(accessibilityRole)] ? element.accessibilityRole : nil;
    BOOL tab = [identifier isEqual:@"tab"] || [role isEqual:@"AXTab"] || [role isEqual:NSAccessibilityRadioButtonRole];
    id value = [object respondsToSelector:@selector(accessibilityValue)] ? element.accessibilityValue : nil;
    BOOL selected = [value isKindOfClass:NSNumber.class] ? [value boolValue] : [value isEqual:@"on"];
    if (tab && selected && [object respondsToSelector:@selector(accessibilityFrame)] && !NSIsEmptyRect(element.accessibilityFrame)) return element;
    NSArray *children = [object respondsToSelector:@selector(accessibilityChildren)] ? element.accessibilityChildren : nil;
    for (id child in children) {
        id<NSAccessibility> found = DPSelected(child, seen, depth + 1);
        if (found) return found;
    }
    return nil;
}

id<NSAccessibility> DPPeekSelectedTab(id root) {
    if ([root isKindOfClass:NSView.class]) {
        NSView *native = DPFindView(root, ^BOOL(NSView *view) {
            if (view.hiddenOrHasHiddenAncestor) return NO;
            if (DPIsKind(view, DPDiaTabView)) return [view.accessibilityValue boolValue];
            if (!DPIsKind(view, DPDiaFavoriteTab)) return NO;
            return DPFindView(view, ^BOOL(NSView *part) {
                return [NSStringFromClass(part.class) hasSuffix:[NSString stringWithUTF8String:DPDiaFavoriteSelectionSuffix]]
                    && !part.hiddenOrHasHiddenAncestor && part.alphaValue > 0 && !NSIsEmptyRect(part.bounds);
            }) != nil;
        });
        if (native) return (id)native;
    }
    return DPSelected(root, [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality], 0);
}

NSRect DPPeekIndicatorFrame(NSRect row, BOOL tile, BOOL flipped) {
    CGFloat side = tile ? 18 : 16;
    CGFloat x = NSMaxX(row) - side - (tile ? -4 : 8);
    CGFloat y = tile ? (flipped ? NSMinY(row) - 4 : NSMaxY(row) - side + 4) : NSMidY(row) - side / 2;
    return NSMakeRect(x, y, side, side);
}
