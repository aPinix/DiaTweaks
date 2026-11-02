#import "BrowserToolbar.h"

enum { DPMiniDestinationWidth = 245, DPMiniDestinationHeaderHeight = 44,
    DPMiniDestinationRowHeight = 46, DPMiniDestinationBottom = 8 };
static inline BOOL DPBrowseDestinationAvailable(DPMiniNativeDestination *choice) {
    return choice.enabled || choice.state == NSControlStateValueOn;
}
NSView *DPBrowseDestinationSurface(NSRect frame);
NSView *DPBrowseDestinationCell(DPMiniNativeDestination *choice);
NSTableRowView *DPBrowseDestinationRow(void);
NSTableView *DPBrowseDestinationTable(void);
