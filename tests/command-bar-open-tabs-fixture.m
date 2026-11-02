#import "Patches/CommandBar/OpenTabs.h"
#import <objc/message.h>

static char DPSwitchSessionKey, DPSwitchInitializedKey, DPSwitchSelectedKey, DPSwitchActivateKey;
@interface DPCommandSwitchSession : NSObject
@property NSInteger identifier;
@end
@implementation DPCommandSwitchSession
@end
static id DPSwitchSession(id self, SEL _cmd) { return DPGet(self, &DPSwitchSessionKey); }
static BOOL DPSwitchInitialized(id self, SEL _cmd) { return !DPGet(self, &DPSwitchInitializedKey) || [DPGet(self, &DPSwitchInitializedKey) boolValue]; }
static void DPSwitchSelected(id self, SEL _cmd, id contents, BOOL activate) {
    DPSet(self, &DPSwitchSelectedKey, contents); DPSet(self, &DPSwitchActivateKey, @(activate));
}

NSDictionary *DPCommandSwitchFixture(id browser, NSWindow *window, NSString *url, NSString *title, NSInteger identifier) {
    static Class pageClass, delegateClass;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        pageClass = objc_allocateClassPair(objc_getClass(DPDiaWebContents), "DPCommandSwitchFixturePage", 0);
        class_addMethod(pageClass, @selector(sessionId), (IMP)DPSwitchSession, "@@:");
        class_addMethod(pageClass, @selector(isInitialized), (IMP)DPSwitchInitialized, "B@:"); objc_registerClassPair(pageClass);
        delegateClass = objc_allocateClassPair(objc_getClass(DPDiaWebContent), "DPCommandSwitchFixtureDelegate", 0);
        class_addMethod(delegateClass, @selector(webContentsSelect:shouldActivate:), (IMP)DPSwitchSelected, "v@:@B"); objc_registerClassPair(delegateClass);
    });
    id<DPBrowseContents> page = [pageClass new];
    [(NSObject *)page setValue:[NSURL URLWithString:url] forKey:@"url"]; [(NSObject *)page setValue:title forKey:@"title"];
    DPCommandSwitchSession *session = [DPCommandSwitchSession new]; session.identifier = identifier;
    DPSet(page, &DPSwitchSessionKey, session);
    id delegate = [delegateClass new]; [page setUIDelegate:delegate];
    ((void (*)(id, SEL, id))objc_msgSend)(browser, @selector(takeOwnershipOfWebContents:), page);
    NSView *host = [NSView new]; host.hidden = YES; [window.contentView addSubview:host]; [page attachToPaneHostView:host];
    return @{@"page":page, @"delegate":delegate, @"session":session, @"host":host};
}
id DPCommandSwitchSelected(NSDictionary *fixture) { return DPGet(fixture[@"delegate"], &DPSwitchSelectedKey); }
BOOL DPCommandSwitchActivated(NSDictionary *fixture) { return [DPGet(fixture[@"delegate"], &DPSwitchActivateKey) boolValue]; }
void DPCommandSwitchInitialized(NSDictionary *fixture, BOOL initialized) { DPSet(fixture[@"page"], &DPSwitchInitializedKey, @(initialized)); }
void DPCommandSwitchCloseNotice(NSDictionary *fixture) {
    ((void (*)(id, SEL, id, id))objc_msgSend)(fixture[@"delegate"], @selector(webContents:didCloseWithSessionID:), fixture[@"page"], fixture[@"session"]);
}
void DPCommandSwitchCleanup(NSDictionary *fixture) {
    DPCommandSwitchCloseNotice(fixture);
    DPSet(fixture[@"delegate"], &DPSwitchSelectedKey, nil);
    [(id<DPBrowseContents>)fixture[@"page"] close]; [fixture[@"host"] removeFromSuperview];
}
