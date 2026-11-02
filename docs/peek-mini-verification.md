# Peek and Dia Mini verification

Tested on Dia 1.56.0 (89901), macOS 27.2, Apple Silicon, on 2 November 2026.

## Automated checks

- `make`: CLI, dylib and 18-entry patch manifest build without compiler warnings.
- `make test-quick-browse`: passes AppKit fixtures using the production Peek and Mini code, with stand-ins for Dia's private classes.
- `scripts/check-tweak-docs`: all 18 tweaks have documentation.

The fixtures cover Mini history and profile isolation, stale autocomplete callbacks, selection after favicon updates, launcher placement on a secondary display, external-link preference on/off, preserving non-web URLs, native page handoff with and without a source webpage, and turning Mini off independently. Peek checks cover modifier handling, special links, opening and expansion timing, interrupted transitions, row and pinned badges, and Reduce Motion.

## Real Dia checks

Used an isolated copy of the official Dia app with a separate Chromium profile and injected development build. The installed Dia app was left untouched.

- Shift-click opens Peek; dismissing and expanding work with real Chromium pages.
- Source row and pinned tile display the destination favicon.
- Mini displays profile history and favicons. Typing produces Dia's native suggestions; Enter opens the selected real page. Escape dismisses the launcher.
- Open in Dia transfers the live page into a selected tab. Starting in a new empty browser window also promotes into that window.
- The user confirmed that Ctrl+Option+Command+N opens Mini while another app is active.
- The launcher's top-right placement is covered by the geometry fixture. Final visual placement inspection was interrupted when the Mac locked.

## Remaining manual coverage

The fixtures replace private classes; they do not prove compatibility with every Dia version. The full `make test` matrix was not run because it loads all upstream patches, including the password helpers, into the installed browser. Real top-tab layout, private windows, a second profile, external links through the OS default-browser route, and website permission prompts still need manual coverage. No animation recording was captured.
