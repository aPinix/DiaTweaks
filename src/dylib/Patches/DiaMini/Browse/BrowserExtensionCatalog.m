#import "BrowserExtensions.h"
#import "Launcher.h"
#import <objc/message.h>

@implementation DPMiniExtensionItem
- (NSString *)status { return !self.enabled ? @"Disabled" : self.hasAction ? @"Open in Dia to use" : @"No toolbar action"; }
@end
@implementation DPMiniExtensionCatalog
@end

static id DPExtensionGet(id object, SEL selector) {
    return [object respondsToSelector:selector] ? ((id (*)(id,SEL))objc_msgSend)(object,selector) : nil;
}
static BOOL DPExtensionFlag(id object, SEL selector) {
    return [object respondsToSelector:selector] && ((BOOL (*)(id,SEL))objc_msgSend)(object,selector);
}

DPMiniExtensionCatalog *DPBrowseMiniExtensionCatalog(DPBrowseWindow *owner) {
    DPMiniExtensionCatalog *catalog = [DPMiniExtensionCatalog new]; catalog.items = @[];
    catalog.message = @"Extensions aren't available in this version of Dia.";
    @try {
        id context = owner.profileContext ?: DPBrowseContext(owner.source);
        id extensions = DPExtensionGet(context, @selector(extensions));
        if (![extensions respondsToSelector:@selector(listExtensions)]) return catalog;
        catalog.available = YES;
        if ([extensions respondsToSelector:@selector(isExtensionSystemReady)] && !DPExtensionFlag(extensions,@selector(isExtensionSystemReady))) {
            catalog.message = @"Extensions are starting…"; return catalog;
        }
        id infos = DPExtensionGet(extensions,@selector(listExtensions));
        if (![infos isKindOfClass:NSArray.class]) { catalog.available = NO; return catalog; }
        NSMutableArray *items = [NSMutableArray array]; NSMutableSet *seen = [NSMutableSet set];
        for (id info in infos) {
            id identifier = DPExtensionGet(info,@selector(id));
            if (![identifier isKindOfClass:NSString.class] || ![identifier length] || [seen containsObject:identifier]) continue;
            DPMiniExtensionItem *item = [DPMiniExtensionItem new]; item.identifier = identifier;
            id name = DPExtensionGet(info,@selector(name));
            item.name = [name isKindOfClass:NSString.class] && [name length] ? name : @"Unnamed extension";
            id icon = DPExtensionGet(info,@selector(icon)); item.icon = [icon isKindOfClass:NSImage.class] ? icon : nil;
            item.enabled = DPExtensionFlag(info,@selector(enabled)); item.hasAction = DPExtensionFlag(info,@selector(hasAction));
            [items addObject:item]; [seen addObject:identifier];
        }
        catalog.items = [items sortedArrayUsingComparator:^NSComparisonResult(DPMiniExtensionItem *a, DPMiniExtensionItem *b) {
            NSComparisonResult order = [a.name localizedCaseInsensitiveCompare:b.name];
            return order == NSOrderedSame ? [a.identifier compare:b.identifier] : order;
        }];
        catalog.ready = YES; catalog.message = catalog.items.count ? @"" : @"No extensions installed in this profile.";
    } @catch (NSException *exception) {
        catalog.available = catalog.ready = NO; catalog.items = @[];
    }
    return catalog;
}
