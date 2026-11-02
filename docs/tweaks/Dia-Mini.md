# Dia Mini

A compact native Chromium window for quick browsing, using the source tab’s profile.

Enable **Settings → Patches → Browsing → Dia Mini**, or `diatweaks enable diaMini`.

- Press **Option+Command+N** (⌥⌘N) from any app, while Dia is running. **File → New Dia Mini** opens the same temporary search box.
- In **Settings → Patches → Dia Mini**, click the shortcut beside **Keyboard shortcut** and press a new combination with Command, Control or Option. Release the key to save it. Escape, clicking elsewhere or leaving the page cancels recording. **Reset** restores ⌥⌘N. Changes apply immediately and survive restarting Dia; the File menu shows the chosen combination.
- The search box opens at the top-right of the screen under the pointer, inset from the menu bar and screen edge. It keeps that corner as results appear.
- Recent results come from the current Dia profile’s history. Start typing for native browser suggestions, use ↑/↓ to select, and press Enter to open the result in a compact Mini window.
- The search panel shows up to five choices, separated from the centered search header by a divider. It has a broad, soft shadow and no bottom hint row. Empty-state and startup messages appear in the list area.
- Native suggestions complete the input with a selected suffix. Normal ↑/↓ previews a choice’s query or address, while retaining your original query for ranking. Deleting a suggested suffix suppresses its immediate return; input-method composition keeps control of its text and keys.
- Type a site-search keyword such as `youtube.com`, then press Tab when its search prompt appears. The provider badge identifies the scope; YouTube uses a red badge and selection. Type a query or choose a recent search from that site. Scoped ↑/↓ retains your input. Backspace on an empty query restores exactly what you typed before Tab: `you` stays `you`, with the caret at the end. Clicking the provider badge does the same. Configured providers come from this Dia profile; YouTube is included unless explicitly disabled.
- In site search, Escape returns to an empty normal input. Another Escape, or a click outside, dismisses the search box. Closing it leaves the page you were working on in place.
- Right-click a web link and select **Open Link in Dia Mini**.
- The separate **[Open external links in Dia Mini](Open-external-links-in-Dia-Mini.md)** option opens links from other apps in Mini first. Dia must be your chosen browser for that link. It does not change clicks inside webpages.
- The browser has a 48-point translucent header with native window controls, a 30-point address pill, centered domain and loading indicator, extensions, copy link and a split **Open in** control. Its initial frame is 1280×950, reduced to fit the screen.
- Click the address pill or press ⌘L to edit the full URL in a centered Command Bar. ⌘T opens it with an empty input. Return loads the result in the same Mini window, including site searches.
- With Command Bar enabled, its configured shortcut (⌘K by default) and **File → Command Bar** also open inside the active Mini. The global ⌥⌘N launcher still creates a new Mini.
- Use ⌘[ / ⌘] for Back / Forward and ⌘R for Reload. **Open in**, ⌘O or ⌘Return moves the live page into a normal tab. The arrow opens a searchable list of Dia’s own destinations, preserving their native names and icons. Dia versions exposing only Profiles show **Search Profiles**. The current destination appears in the button; Arc’s Spaces are never imported.
- The puzzle button opens a compact navy list of enabled extension icons and single-line names. Disabled extensions are omitted. Icons use the source profile’s installed extension assets when available, with Dia’s native icon as fallback. The header’s **Open in** button transfers this page to a regular tab where extension actions are available.
- Drag the header, including the address pill and action controls, to move Mini. A click still activates the corresponding control; movement of four points starts a window drag. The traffic lights retain their native actions.
- Mini remembers the browser window’s size after a manual resize, including across restarts. Saved sizes are reduced to fit the current display. A page canvas keeps the full window visible while a URL is loading.
- Escape or ⌘W first closes an open Command Bar; the Mini remains. In site search, Escape first leaves the search scope. With the bar closed, Escape or ⌘W closes Mini.
- Escape or the close button closes the temporary window. Turning Dia Mini off closes its windows and removes its File menu command.

Mini and Peek have independent switches. Mini is a separate, resizable window, rather than a child overlay.

## Limits

This is experimental and depends on Dia’s private native APIs. It is a compact browsing surface, without Dia’s Chat or sidebar. Mini’s puzzle button shows an extension catalogue; extension action popups require a regular Dia tab because Dia’s shipped action API targets tracked browser tabs. Use **Open in Dia** for those actions and website permission dialogs.

Dia must be running for its global shortcut to work. The recorder rejects conflicting Dia menu shortcuts and reports global registration failures without saving the rejected choice. macOS may intercept reserved system shortcuts before they reach the recorder. The File menu command remains available. With no browser window available, Mini asks Dia to prepare a temporary background source window. The source is removed when no Mini needs it, unless you promote a page into it.

Mini uses the current source profile, including its private browsing context. Native history supplies recents; Mini’s additional fallback list stays in memory and is scoped to its source factory. An existing Mini can keep navigating after its source window closes. Opening in a destination first transfers the live page into its source window. For another destination, Dia’s own move action then handles the move. A failed initial handoff restores Mini; if a later move is unavailable, the page stays in Dia and a message explains how to use its native Move menu. Mini never replays a callback belonging to another tab.

## Verification

Run `make test-quick-browse` for the AppKit fixtures. In real Dia, check the global shortcut, completion, arrows, site search, ⌘L/⌘T/⌘K and same-window navigation. Resize Mini, test the destination picker and live-page handoff, close the source window, and check Escape / ⌘W dismiss the bar before the owner. Check both tab layouts, on/off states and external links. Disable Mini while Peek is open and confirm Peek still works.
