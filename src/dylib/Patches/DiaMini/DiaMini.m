#import "Commands/QuickBrowse/QuickBrowse.h"

DP_PATCH(DPDiaMini) {
    .key = @"diaMini", .order = 220,
    .title = @"Dia Mini",
    .detail = @"Press ⌃⌥⌘N from any app for a temporary search box with recent results and suggestions from the current Dia profile. Enter opens the result in a compact window. Escape closes it; Open in Dia keeps the page as a tab. Experimental.",
    .symbol = @"macwindow", .tint = @"systemTealColor", .section = @"Browsing",
    .classes = DPClasses(DPDiaBrowser, DPDiaWebContents, DPDiaWebContentsConfiguration, DPDiaTablessDelegate),
    .install = DPInstallQuickBrowse, .apply = DPBrowseApply, .verify = DPBrowseVerify,
};
