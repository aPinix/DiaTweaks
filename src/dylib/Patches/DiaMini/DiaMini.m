#import "Browse/QuickBrowse.h"

DP_PATCH(DPDiaMini) {
    .key = @"diaMini", .order = 220,
    .title = @"Dia Mini",
    .detail = @"Default shortcut: ⌥⌘N from any app. Change it below. A temporary search box shows recent results and suggestions from the current Dia profile. Enter opens a compact window; Open in Dia keeps the page as a tab. Experimental.",
    .symbol = @"macwindow", .tint = @"systemTealColor", .section = @"Browsing",
    .classes = DPClasses(DPDiaBrowser, DPDiaWebContents, DPDiaWebContentsConfiguration, DPDiaTablessDelegate),
    .install = DPInstallQuickBrowse, .apply = DPBrowseApply, .verify = DPBrowseVerify,
};
