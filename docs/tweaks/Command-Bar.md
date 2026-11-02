# Command Bar

Search, enter a web address or search within a website, then open the result in a regular Dia tab using the current window and profile.

Enable **Settings → Patches → Browsing → Command Bar**, or `diatweaks enable commandBar`.

- Press **Command+K** (⌘K) in Dia, or choose **File → Command Bar**. The bar appears centered in the current browser window, with up to five choices.
- Type an address or search, use ↑/↓ to select a choice, then press Return to open a foreground tab. Escape or clicking outside dismisses the bar.
- Normal suggestions complete the input with a selected suffix. Moving through them previews their query or address while retaining the original request for ranking. Deleting a suffix suppresses its immediate restoration, and input-method composition keeps control of its text and keys.
- A matching tracked tab in the current regular window can show **Switch to Tab**. Return selects that exact tab without loading or creating another page. In an existing Mini, Return navigates that same Mini and does not offer main-window tab switching.
- For site search, type a configured website keyword, such as `youtube.com`, then press Tab when **Search YouTube · Tab** appears. A provider badge identifies the scope; YouTube uses a red badge and selection.
- Enter your query and press Return. Recent searches from that provider can also appear. Scoped ↑/↓ changes the selected query without replacing your input. Backspace on an empty query restores your original input before Tab, including a partial prefix such as `you`; clicking the provider badge does the same. Completion stays suppressed until you type again. Escape leaves the scope for an empty normal input, and a second Escape dismisses the bar.
- In **Settings → Patches → Command Bar**, record another keyboard shortcut or use **Reset** to restore ⌘K. Choosing ⌘T replaces Dia’s New Tab shortcut while Command Bar is enabled. Changing or disabling the shortcut restores the native binding. Other conflicting menu shortcuts and Dia Mini’s shortcut are rejected.

The shortcut works within Dia, including inside Mini. Mini also provides ⌘L for editing its current URL and ⌘T for an empty bar when the Command Bar patch is off. Its separate global shortcut opens a new-Mini launcher. Both bars share site search and can be enabled independently. Mini reserves ⌘L, ⌘W, ⌘O, ⌘Return and its history/reload keys; the shortcut recorder rejects those combinations.

Site-search providers come from the current Dia profile. YouTube is included when it has not been configured; a disabled YouTube provider is respected. Custom providers can use standard HTTP/HTTPS search templates. Scoped search uses that provider’s history and, when configured, its native keyword suggestions. An unconfigured YouTube query is never passed to the default engine for autocomplete.

## Limits and verification

Only web addresses are supported. This experimental patch depends on Dia’s private APIs; unsupported versions disable it. A tab-opening failure keeps the bar available to retry. Once Dia has adopted a new tab, that tab belongs to Dia even if the bar is dismissed immediately afterward.

Tab switching covers tracked, initialized web pages in the current window and profile. Dormant session-only tabs and Arc’s full command catalogue are outside this implementation.

## Reference behavior

Compared directly with Command Bar and Little Arc in Arc 1.171.0: `you` completes to `youtube.com`, Tab enters YouTube search, normal arrows preview addresses or literal searches, scoped arrows retain the input, empty Backspace leaves site search, and scoped Escape returns to an empty normal input before dismissal. Space stays ordinary query text.

Dia’s shipped `ArcAutocompleteMatch.h` supplies `inlineAutocompleteText`, `fillIntoEdit` and `allowedToBeDefaultMatch`; these drive completion rather than guessed page titles. `ArcWebContentsUIDelegate.h` supplies `webContentsSelect:shouldActivate:` for tab switching, with `ArcSessionID.identifier` used to reject stale identities. UI selection still requires a native check because that delegate method returns no result. This reconstructs the observed navigation flow; it does not reproduce every Arc command or ranking rule.

Run `make test-quick-browse` for isolated AppKit checks. In the actual Dia app, check regular and site searches in both tab layouts, with Mini off and on. Check opening from an empty browser window, shortcut capture and reset, ⌘T takeover and restoration, Escape, and disabling the patch while its bar is open. Use a recording to show the bar, Tab-to-search, query results and the resulting normal tab.
