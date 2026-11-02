#import "Patches/DiaMini/Browse/BrowserToolbar.h"

@interface DPMiniProfileIDFixture : NSObject
@property(copy) NSString *directoryBasename;
@property BOOL isIncognito;
@end
@implementation DPMiniProfileIDFixture
@end
@interface DPMiniProfileFixture : NSObject
@property(strong, getter=id) DPMiniProfileIDFixture *identity;
@end
@implementation DPMiniProfileFixture
@end
static DPMiniProfileFixture *DPMiniProfile(NSString *directory, BOOL private) {
    DPMiniProfileFixture *context = [DPMiniProfileFixture new]; context.identity = [DPMiniProfileIDFixture new];
    context.identity.directoryBasename = directory; context.identity.isIncognito = private; return context;
}

void DPTestMiniBrowserProfiles(DPBrowseWindow *owner, DPBrowseSource *destination) {
    id saved = owner.profileContext, target = [destination.browser valueForKey:@"context"];
    owner.profileContext = DPMiniProfile(@"Profile One", NO);
    [destination.browser setValue:DPMiniProfile(@"Profile One", NO) forKey:@"context"];
    NSCAssert([owner canPromoteToSource:destination], @"distinct native wrappers match by regular profile identity");
    [destination.browser setValue:DPMiniProfile(@"Profile Two", NO) forKey:@"context"];
    NSCAssert(![owner canPromoteToSource:destination], @"another profile directory cannot receive the page");
    [destination.browser setValue:DPMiniProfile(@"Profile One", YES) forKey:@"context"];
    NSCAssert(![owner canPromoteToSource:destination], @"regular pages cannot enter a private context with the same directory");
    owner.profileContext = DPMiniProfile(@"Profile One", YES);
    NSCAssert(![owner canPromoteToSource:destination], @"separate private wrappers require exact context identity");
    NSCAssert([owner canPromoteToSource:owner.source], @"the original immutable factory remains a valid private destination");
    [destination.browser setValue:owner.profileContext forKey:@"context"];
    NSCAssert([owner canPromoteToSource:destination], @"a shared private context keeps its exact identity");
    owner.profileContext = saved; [destination.browser setValue:target forKey:@"context"];
}
