# Peek

Preview a link over the current Dia window, using the source tab’s Chromium browser and profile.

Enable **Settings → Patches → Browsing → Peek**, or `diatweaks enable peek`.

- Shift-click a link. A card grows from the clicked point without stretching the page, while the background scales to 97.5% around its center. The sidebar remains usable.
- Growth starts immediately, with a temporary page canvas beneath Chromium while it loads. The live host stays visible, so page pixels appear as soon as they paint. First paint removes the canvas without replaying the entrance; slow sites cannot hold up the card or its controls.
- The whole browser-content frame, including its rounded edge, stays sharp and fades to 20% opacity. The native window theme shows through beneath it. Peek sits immediately above that frame and below the native sidebar, so revealing a hidden sidebar keeps it above the preview.
- Card edges align to physical pixels. The webpage extends one pixel underneath the rounded clip, preventing a backing strip from appearing beside the content at fractional sizes.
- Press Escape or ⌘W, use the close button, or click outside the card to dismiss it. The card returns to the original clicked point with a 220 ms fade, with the controls fading out and the page behind returning together. Moving the pointer or repositioning the window does not change that destination.
- Click **Open as Tab** or press ⌘O to expand the card into a regular tab. The existing live page keeps its state and navigation history.
- Use the split button to animate the preview into Dia’s split view.
- The three 34-point circular controls sit in the right margin, inset from the card’s top. Their symbols use centered vector strokes at the display’s backing scale. Each circle has space inside its button area to grow without clipping. Hover and press feedback animate from their current state; Reduce Motion keeps that feedback stationary.
- A favicon badge identifies the source tab: inside the right edge for a row, or overlapping the top-right corner for a pinned tile. A tab row reserves a separate slot, keeping Dia’s close button to the favicon’s left and shortening long titles as needed. The badge updates as the preview’s favicon loads and disappears when Peek closes; the row then regains its full width.

Only one Peek stays open per source window. It follows that window when moved or resized and closes with it. Turning the patch off dismisses its previews. It works with both sidebar and top tabs.

## Limits

This is experimental and uses private Objective-C APIs that Dia can change. Missing required classes disable the feature. Only HTTP and HTTPS links are supported; special browser URLs keep their usual behavior. Command-click, Option-click and Command-Shift-click keep their existing behavior.

The implementation builds on [Ryan’s Peek PR #2](https://github.com/JaceThings/DiaTweaks/pull/2). It uses native navigation requests and keeps the live Chromium page during expansion. Popups and website permission prompts need a regular tab. Peek does not automatically intercept normal clicks from pinned tabs.

Reduce Motion uses short opacity transitions instead of scaling or expansion. Opening, closing and expansion start from the currently displayed layer state; Escape can cancel an expansion before the page is transferred.

## Verification

`make test-quick-browse` runs AppKit fixtures without touching Dia. Test real rendering, navigation, link gestures and tab transfer on your installed Dia too; the fixtures replace Dia’s private classes.

For a manual check, try Shift-click, Escape, clicking outside, resizing, expanding and splitting. Check source badges on a tab row and a pinned tile, with both tab layouts. Try expanding while the opening animation is still running, cancel expansion with Escape, and enable Reduce Motion. Also check a private window and a second profile. Turn Peek off while one is open; Dia Mini should remain available.
