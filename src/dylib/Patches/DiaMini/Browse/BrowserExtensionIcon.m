#import "BrowserExtensions.h"
#import <objc/message.h>

static id DPMiniIconGet(id object, SEL selector) {
    return [object respondsToSelector:selector] ? ((id (*)(id,SEL))objc_msgSend)(object,selector) : nil;
}
NSImage *DPBrowseInstalledExtensionIcon(id context, NSString *identifier, NSString *version) {
    NSString *profile = DPMiniIconGet(DPMiniIconGet(context,@selector(id)),@selector(directoryBasename));
    if (![profile isKindOfClass:NSString.class] || !profile.length || ![profile.lastPathComponent isEqual:profile]
        || [profile isEqual:@".."] || identifier.length != 32
        || [identifier rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnop"] invertedSet]].location != NSNotFound) return nil;
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *directory = [support URLByAppendingPathComponent:[NSString stringWithFormat:@"Dia/User Data/%@/Extensions/%@",profile,identifier]];
    NSArray<NSURL *> *versions = [NSFileManager.defaultManager contentsOfDirectoryAtURL:directory includingPropertiesForKeys:nil options:0 error:nil];
    for (NSURL *root in versions) {
        NSString *name = root.lastPathComponent;
        if (![version isKindOfClass:NSString.class] || !([name isEqual:version] || [name hasPrefix:[version stringByAppendingString:@"_"]])) continue;
        NSData *data = [NSData dataWithContentsOfURL:[root URLByAppendingPathComponent:@"manifest.json"]];
        NSDictionary *manifest = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if (![manifest isKindOfClass:NSDictionary.class]) continue;
        id action = manifest[@"action"] ?: manifest[@"browser_action"];
        id icons = [action isKindOfClass:NSDictionary.class] ? action[@"default_icon"] : nil;
        icons = icons ?: manifest[@"icons"];
        NSString *path = [icons isKindOfClass:NSString.class] ? icons : nil;
        if ([icons isKindOfClass:NSDictionary.class]) {
            NSArray *keys = [[icons allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a,id b) { return [a compare:b options:NSNumericSearch]; }];
            for (NSString *key in keys) { path = icons[key]; if (key.integerValue >= 22) break; }
        }
        if (![path isKindOfClass:NSString.class] || path.isAbsolutePath) continue;
        NSURL *file = [[root URLByAppendingPathComponent:path] URLByResolvingSymlinksInPath];
        if (![file.path hasPrefix:[root.URLByResolvingSymlinksInPath.path stringByAppendingString:@"/"]]) continue;
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:file];
        if (image.valid) return image;
    }
    return nil;
}
