# Peek and Dia Mini verification

Tested on Dia 1.56.0 (89901), macOS 27.2, Apple Silicon, on 2 November 2026.

## Automated checks

- `make`: CLI, dylib and 18-entry patch manifest build without compiler warnings.
- `make test-quick-browse`: passes AppKit fixtures using the production Peek and Mini code, with stand-ins for Dia's private classes.
- `scripts/check-tweak-docs`: the unchanged upstream gate reports missing wiki pages/sidebar entries for Peek, Dia Mini and Open external links in Dia Mini. The local notes do not satisfy that gate; the guide assigns those wiki pages and preview media to the upstream maintainer before merge.

The fixtures cover Mini history and profile isolation, stale autocomplete callbacks, selection after favicon updates, launcher placement on a secondary display, external-link preference on/off, preserving non-web URLs, native page handoff with and without a source webpage, and turning Mini off independently. Peek checks cover modifier handling, special links, opening and expansion timing, interrupted transitions, row and pinned badges, and Reduce Motion. The favicon regression checks confirm a separate close-button slot, the original button action, title space with/without hover, repeated layouts, narrower rows and restoration of the full row width after dismissal.

## Real Dia checks

Initial checks used an isolated copy of the official Dia app with a separate Chromium profile and injected development build.

- Shift-click opens Peek; dismissing and expanding work with real Chromium pages.
- Source row and pinned tile display the destination favicon.
- Mini displays profile history and favicons. Typing produces Dia's native suggestions; Enter opens the selected real page. Escape dismisses the launcher.
- Open in Dia transfers the live page into a selected tab. Starting in a new empty browser window also promotes into that window.
- The user confirmed that Ctrl+Option+Command+N opens Mini while another app is active.
- The launcher's top-right placement was visually confirmed on the active display with two displays connected. Its top and right edges stay fixed as the list grows from four recent pages to six suggestions. Secondary-display geometry is also covered by the fixture.

## Existing Dia installation

After the user's installation approval, ran `DIAPATCH_NO_RELAUNCH=1 ./install.sh --yes`, quit Dia normally, applied the staged app and reopened `/Applications/Dia.app`. Dia retained its existing profile and browser session. The full Settings → Patches page is present, and Peek and Dia Mini were enabled there. Peek also opened from a disposable Example Domain tab in the existing profile.

The optional Rust `diatweaks` command was skipped because Rust is unavailable on this Mac. The installed patcher and Settings controls work independently of that optional command.

## Remaining manual coverage

The fixtures replace private classes; they do not prove compatibility with every Dia version. `make test` in both layouts, final native favicon spacing/close interaction, real top-tab layout, private windows, a second profile, external links through the OS default-browser route and website permission prompts still need manual coverage. The native checks currently await a brief period without simultaneous browser interaction. No animation recording has been captured. Do not mark the PR template's proof/layout checklist complete until those checks and recordings exist.
