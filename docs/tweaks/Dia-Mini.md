# Dia Mini

A compact native Chromium window for quick browsing, using the source tab’s profile.

Enable **Settings → Patches → Browsing → Dia Mini**, or `diatweaks enable diaMini`.

- Press **Option+Command+N** (⌥⌘N) from any app, while Dia is running. **File → New Dia Mini** opens the same temporary search box.
- In **Settings → Patches → Dia Mini**, click the shortcut beside **Keyboard shortcut** and press a new combination with Command, Control or Option. Release the key to save it. Escape, clicking elsewhere or leaving the page cancels recording. **Reset** restores ⌥⌘N. Changes apply immediately and survive restarting Dia; the File menu shows the chosen combination.
- The search box opens at the top-right of the screen under the pointer, inset from the menu bar and screen edge. It keeps that corner as results appear.
- Recent results come from the current Dia profile’s history. Start typing for native browser suggestions, use ↑/↓ to select, and press Enter to open the result in a compact Mini window.
- The search panel shows up to five choices, separated from the centered search header by a divider. It has a broad, soft shadow and no bottom hint row. Empty-state and startup messages appear in the list area.
- Native suggestions complete the input with a selected suffix. Normal ↑/↓ previews a choice’s query or address, while retaining your original query for ranking. Deleting a suggested suffix suppresses its immediate return; input-method composition keeps control of its text and keys.
- Type a site-search keyword such as `youtube.com`, then press Tab when its search prompt appears. The provider badge identifies the scope; YouTube uses a red badge and selection. Type a query or choose a recent search from that site. Scoped ↑/↓ retains your input. Backspace on an empty query restores the site address. Configured providers come from this Dia profile; YouTube is included unless explicitly disabled.
- In site search, Escape returns to an empty normal input. Another Escape, or a click outside, dismisses the search box. Closing it leaves the page you were working on in place.
- Right-click a web link and select **Open Link in Dia Mini**.
- The separate **[Open external links in Dia Mini](Open-external-links-in-Dia-Mini.md)** option opens links from other apps in Mini first. Dia must be your chosen browser for that link. It does not change clicks inside webpages.
- Enter a web address or search in the address field. ⌘L selects it.
- Use Back, Forward and Reload, or **Open in Dia** (⌘Return) to keep the existing page as a normal tab.
- Escape or the close button closes the temporary window. Turning Dia Mini off closes its windows and removes its File menu command.

Mini and Peek have independent switches. Mini is a separate, resizable window, rather than a child overlay.

## Limits

This is experimental and depends on Dia’s private native APIs. It is a compact browsing surface, without Dia’s Chat, sidebar or extension toolbar. Use **Open in Dia** for those features and website permission dialogs.

Dia must be running for its global shortcut to work. The recorder rejects conflicting Dia menu shortcuts and reports global registration failures without saving the rejected choice. macOS may intercept reserved system shortcuts before they reach the recorder. The File menu command remains available. With no browser window available, Mini asks Dia to prepare a temporary background source window. The source is removed when no Mini needs it, unless you promote a page into it.

Mini uses the current source profile, including its private browsing context; it does not choose profiles for you. Native history supplies recents; Mini’s additional fallback list stays in memory and is scoped to its source factory. Keep the source tab available when moving a Mini page into a regular tab.

## Verification

Run `make test-quick-browse` for the AppKit fixtures. In real Dia, check the shortcut from another app, recent results, fast typing, ↑/↓, Enter and Escape. Also check a bare domain, a full URL, a search, Back/Forward, Reload, ⌘L, **Open in Dia**, and external links with their option on and off. Check both tab layouts, private browsing and a second profile. Disable Mini while Peek is open and confirm Peek still works.
