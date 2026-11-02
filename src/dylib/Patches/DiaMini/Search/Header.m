#import "Provider.h"
#import <objc/message.h>

@implementation DPMiniLauncher (SiteSearchHeader)
- (void)buildSiteSearch {
    self.sitePrompt = [NSButton buttonWithTitle:@"" target:self action:@selector(enterSiteSearch)];
    self.sitePrompt.bordered = NO; self.sitePrompt.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
    self.sitePrompt.identifier = @"DiaSearchSitePrompt";
    [self.window.contentView addSubview:self.sitePrompt];
    self.siteBadge = [NSButton buttonWithTitle:@"" target:self action:@selector(leaveSiteSearch)];
    self.siteBadge.bordered = NO; self.siteBadge.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    self.siteBadge.wantsLayer = YES; self.siteBadge.layer.cornerRadius = 12;
    self.siteBadge.identifier = @"DiaSearchSiteBadge";
    [self.window.contentView addSubview:self.siteBadge];
    [self refreshSiteSearchHeader];
}
- (void)refreshSiteSearchHeader {
    CGFloat width = NSWidth(self.window.contentView.bounds), x = 50, right = 54;
    DPSiteSearchProvider *provider = self.siteProvider ?: self.siteCandidate;
    self.sitePrompt.hidden = !self.siteCandidate || self.siteProvider;
    self.siteBadge.hidden = !self.siteProvider;
    self.closeButton.hidden = !self.sitePrompt.hidden;
    if (!self.sitePrompt.hidden) {
        NSString *title = [NSString stringWithFormat:@"Search %@   Tab", provider.name];
        NSMutableAttributedString *label = [[NSMutableAttributedString alloc] initWithString:title attributes:@{
            NSFontAttributeName:self.sitePrompt.font, NSForegroundColorAttributeName:NSColor.secondaryLabelColor}];
        [label addAttributes:@{NSBackgroundColorAttributeName:NSColor.controlColor,
            NSFontAttributeName:[NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightSemibold]} range:NSMakeRange(title.length - 3, 3)];
        self.sitePrompt.attributedTitle = label;
        CGFloat promptWidth = MIN(width * 0.48, label.size.width + 12);
        self.sitePrompt.frame = NSMakeRect(width - 22 - promptWidth, 20, promptWidth, 24);
        self.sitePrompt.accessibilityLabel = [NSString stringWithFormat:@"Search %@, Tab", provider.name];
        right = promptWidth + 32;
    }
    if (self.siteProvider) {
        NSDictionary *attributes = @{NSFontAttributeName:self.siteBadge.font, NSForegroundColorAttributeName:NSColor.whiteColor};
        self.siteBadge.attributedTitle = [[NSAttributedString alloc] initWithString:provider.name attributes:attributes];
        CGFloat badgeWidth = MIN(width * 0.4, [provider.name sizeWithAttributes:attributes].width + 20);
        self.siteBadge.frame = NSMakeRect(x, 20, badgeWidth, 24);
        self.siteBadge.layer.backgroundColor = provider.accent.CGColor;
        self.siteBadge.accessibilityLabel = [NSString stringWithFormat:@"Leave %@ search", provider.name];
        x += badgeWidth + 10;
    }
    NSRect field = self.search.frame; field.origin.x = x; field.size.width = MAX(40, width - x - right); self.search.frame = field;
    self.search.placeholderString = self.siteProvider ? @"Search…" : @"Search or Enter URL…";
    self.search.accessibilityLabel = self.siteProvider ? [NSString stringWithFormat:@"Search %@", provider.name] : @"Search or Enter URL";
    self.searchIcon.contentTintColor = self.siteCandidate ? provider.accent : NSColor.labelColor;
    self.searchIcon.image = self.siteCandidate ? provider.icon ?: [NSImage imageWithSystemSymbolName:[provider.host isEqual:@"youtube.com"] ? @"play.rectangle.fill" : @"globe" accessibilityDescription:provider.name]
        : [NSImage imageWithSystemSymbolName:@"magnifyingglass" accessibilityDescription:@"Search"];
    id context = DPBrowseContext(self.source);
    if (!self.siteCandidate || provider.icon || !provider.homeURL || ![context respondsToSelector:@selector(favicon:completion:)]) return;
    __weak DPMiniLauncher *weak = self;
    void (*favicon)(id,SEL,NSURL *,void (^)(id)) = (void *)objc_msgSend;
    favicon(context, @selector(favicon:completion:), provider.homeURL, ^(id image) {
        if (![image isKindOfClass:NSImage.class]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DPMiniLauncher *launcher = weak;
            if (launcher.siteCandidate != provider) return;
            provider.icon = image; launcher.searchIcon.image = image;
        });
    });
}
@end
