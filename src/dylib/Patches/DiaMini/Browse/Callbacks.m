#import "QuickBrowse.h"
#import <objc/message.h>

static DPBrowseWindow *DPBrowseOwner(id contents) {
    for (DPBrowseWindow *preview in DPBrowseWindows) if (preview.contents == contents) return preview;
    return nil;
}

static void DPBrowse_closed(id self, SEL _cmd, id contents, id session) {
    DPBrowseWindow *preview = DPBrowseOwner(contents);
    if (preview) { dispatch_async(dispatch_get_main_queue(), ^{ [preview close]; }); return; }
    DPCallOriginal(DPBrowse_closed, self, contents, session);
}

static void DPBrowse_popup(id self, SEL _cmd, id contents, id child, id url, NSInteger disposition) {
    DPBrowseWindow *preview = DPBrowseOwner(contents);
    if (!preview) return DPCallOriginal(DPBrowse_popup, self, contents, child, url, disposition);
    id delegate = preview.source.delegate, source = preview.source.contents;
    if (delegate && source) {
        void (*open)(id, SEL, id, id, id, NSInteger) = (void *)objc_msgSend;
        open(delegate, _cmd, source, child, url, disposition);
    } else if (DPBrowseSourceUsable(preview.source)) {
        void (*adopt)(id,SEL,id,id,BOOL) = (void *)objc_msgSend;
        adopt(preview.source.browserDelegate,@selector(browser:didCreateNewWebContents:isActive:),preview.source.browser,child,disposition != 3);
    } else [(id<DPBrowseContents>)child close];
}

void DPBrowseInstallCallbacks(void) {
    DPHook(DPDiaTablessDelegate, @selector(webContents:didCloseWithSessionID:), (IMP)DPBrowse_closed);
    DPHook(DPDiaTablessDelegate, @selector(webContents:didCreateNewWebContent:targetURL:disposition:), (IMP)DPBrowse_popup);
}
