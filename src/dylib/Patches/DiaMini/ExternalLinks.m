#import "Browse/QuickBrowse.h"

DP_PATCH(DPDiaMiniExternal) {
    .key = @"diaMiniExternalLinks", .order = 221,
    .title = @"Open external links in Dia Mini",
    .detail = @"Open web links from other apps in a temporary Dia Mini window first. Open in Dia keeps the page as a regular tab. Links clicked inside webpages keep their normal behavior.",
    .symbol = @"arrow.up.forward.app", .tint = @"systemTealColor", .section = @"Browsing",
    .requires = @"diaMini",
    .apply = DPBrowseApply,
};
