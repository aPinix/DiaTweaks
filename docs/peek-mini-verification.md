# Peek and Dia Mini verification

Tested on Dia 1.56.0 (89901), macOS 27.2, Apple Silicon, on 2 November 2026.

## Automated checks

- `make`: CLI, dylib and 18-entry patch manifest build without compiler warnings.
- `make test-quick-browse`: passes AppKit fixtures using the production Peek and Mini code, with stand-ins for Dia's private classes.
- `make test`: the final installed build passes all 34 scenarios with sidebar tabs (`vertical`) and all 34 with top tabs (`horizontal`), with no unavailable patches or safe mode. Reports are saved locally as `build/test-sidebar.json` and `build/test-top.json`.
- `scripts/check-tweak-docs`: the unchanged upstream gate reports missing wiki pages/sidebar entries for Peek, Dia Mini and Open external links in Dia Mini. The local notes do not satisfy that gate; the guide assigns those wiki pages and preview media to the upstream maintainer before merge.

The fixtures cover Mini history and profile isolation, stale autocomplete callbacks, selection after favicon updates, launcher placement on a secondary display, external-link preference on/off, preserving non-web URLs, native page handoff with and without a source webpage, and turning Mini off independently. Peek checks cover modifier handling, special links, opening and expansion timing, interrupted transitions, row and pinned badges, and Reduce Motion. The favicon regression checks confirm a separate close-button slot, the original button action, title space with/without hover, repeated layouts, narrower rows and restoration of the full row width after dismissal. Additional checks cover fading the complete browser frame without a painted overlay, a revealed sidebar receiving clicks above Peek, vector symbols sharing their circle's center, and hover growth fitting inside each button area.

## Real Dia checks

Initial checks used an isolated copy of the official Dia app with a separate Chromium profile and injected development build.

- Shift-click opens Peek; dismissing and expanding work with real Chromium pages.
- Source row and pinned tile display the destination favicon.
- Mini displays profile history and favicons. Typing produces Dia's native suggestions; Enter opens the selected real page. Escape dismisses the launcher.
- Open in Dia transfers the live page into a selected tab. Starting in a new empty browser window also promotes into that window.
- The user confirmed that Mini's global shortcut works while another app is active. Its current default is Option+Command+N and can be changed on Mini's Patches page.
- The launcher's top-right placement was visually confirmed on the active display with two displays connected. Its top and right edges stay fixed as the list grows from four recent pages to six suggestions. Secondary-display geometry is also covered by the fixture.

## Existing Dia installation

After the user's installation approval, ran `DIAPATCH_NO_RELAUNCH=1 ./install.sh --yes`, quit Dia normally, applied the staged app and reopened `/Applications/Dia.app`. Dia retained its existing profile and browser session. The full Settings → Patches page is present, and Peek and Dia Mini were enabled there. Peek also opened from a disposable Example Domain tab in the existing profile.

The optional Rust `diatweaks` command was skipped because Rust is unavailable on this Mac. The installed patcher and Settings controls work independently of that optional command.

The final Peek changes were built, installed and checked in this existing Dia installation:

- Peek opens in both layouts. The whole browser-content frame, including its rounded edge, scales back and fades while its contents stay sharp.
- The regular source row has a padded favicon tile; a pinned source displays the corner badge.
- All three controls render complete circles with centered vector symbols. Pointer presses dismiss and expand the preview. Expansion leaves the live page in a regular tab; the temporary test tab was then closed.
- Changing between sidebar and top tabs while Peek is open resizes the card with the content frame. The user's sidebar layout was restored and saved with a normal quit, then Dia was reopened without test mode.

## Local proof

`build/proof/vertical-peek-final.mp4` records the final controls, opening, dismissal and expansion. `build/proof/horizontal-peek-final.mp4` records Peek with top tabs. Both are silent H.264 videos at 1120×700 and 60 fps, encoded with the guide's settings. `build/proof/peek-controls-final.png` shows the native controls at their actual rendered size. Earlier recordings and the user's supplied screenshots document the previous appearance. These local artifacts are ignored by Git; review recordings before attaching them to an upstream PR.

## Remaining manual coverage

The fixtures replace private classes; they do not prove compatibility with every Dia version. Native edge-hover sidebar reveal, the close-button hover beside a regular row badge, private windows, a second profile, external links through the OS default-browser route and website permission prompts still need manual coverage. Sidebar stacking and close-button spacing have fixture coverage, but those fixtures are not a substitute for the remaining pointer-driven checks. The missing upstream wiki pages and previews still require a maintainer before merge. No upstream PR has been submitted.

## Edge seam and dismissal follow-up

The follow-up build also passes `make`, `make test-quick-browse`, and all 34 native scenarios in each layout. Its reports are `build/test-sidebar-seam.json` and `build/test-top-seam.json`. The new fixture cases check physical pixel alignment at odd and fractional widths, a one-pixel margin beneath the clip, transparent backing, and keeping the live page attached through a gentle dismissal. A close before the first display tick now uses the opening seed rather than jumping to the full-size model.

Native window captures of the yellow Dia page check the straight right edge in both layouts: `build/proof/peek-seam-sidebar-window.png` and `build/proof/peek-seam-top-window.png`. `build/proof/peek-seam-close-before.mp4` preserves the earlier collapse animation; `build/proof/peek-seam-close-after.mp4` records the new close and reopening. The encoded recordings use the contribution guide's 1120×700, 60 fps H.264 settings. All proof remains local and ignored by Git.

## Configurable Mini shortcut

The default is now Option+Command+N. The Mini detail page includes a shortcut recorder and Reset button. Settings changes update the global registration and File menu together. Recording pauses Mini's binding and saves after key release; Escape, focus loss or leaving the page cancels it. Rejected registrations and failed preference writes retain the previous choice.

- `make` builds without compiler warnings. `make test-quick-browse` passes the original fixtures plus shortcut tests for defaults, capture, cancellation, reset, menu/global conflicts, malformed preferences, disabled Mini, write rollback, and persistence read by a separate process. Shortcut fixtures use an isolated preferences domain and fake global registrations.
- The final native build passes all 34 scenarios with sidebar tabs and all 34 with top tabs. Reports are `build/test-sidebar-mini-shortcut.json` and `build/test-top-mini-shortcut.json`.
- Recorded Control+Option+Command+M in the actual settings control, quit Dia normally and reopened it. The control retained that combination and Mini opened with it. The user then confirmed that it also opened Mini from another app. Reset restored Option+Command+N afterward.
- `build/proof/mini-shortcut-settings-custom.png` shows the persisted custom binding, and `build/proof/mini-shortcut-settings-default.png` shows the final default. Both are native settings-window captures kept local and ignored by Git.

The unchanged documentation gate still reports the three missing upstream wiki pages and sidebar links listed above; no new patch key or wiki page is introduced by this update.

## Peek from the clicked link

Opening and dismissal now share the saved mouse-down point. The card scales uniformly from 10% at that point and returns there on dismissal, keeping the 220 ms closing fade. This replaces the earlier in-place recession described above. Pointer movement does not change the destination, and moving the window keeps the point attached to its content. Reduce Motion still fades without scaling.

Transforms use the parent layer's coordinates. AppKit flips the card's backing layer when it displays, which made an earlier local-coordinate calculation reverse the vertical direction. The rendered-hierarchy regression test detects that error before the correction and passes afterward. It checks every corner, the center, different anchors, window movement, remembered input, matching opening/closing endpoints and dismissal before the first display tick. An existing history fixture now waits for its callback instead of assuming it arrives within 20 ms.

- `make` and `make test-quick-browse` pass. The build has no compiler warnings.
- The installed build passes all 34 native scenarios in each layout, with no unavailable patches or safe mode. Reports: `build/test-sidebar-peek-origin.json` and `build/test-top-peek-origin.json`.
- Native recordings show opening and closing from an upper navigation link and a lower release-heading link in both layouts. Frame-by-frame review confirms that dismissal travels toward the correct link in each direction. Dia was reopened normally with the original sidebar layout and profile afterward.
- Local proof: `build/proof/peek-origin-before.mp4`, `build/proof/peek-origin-sidebar-after.mp4` and `build/proof/peek-origin-top-after.mp4`. The final recordings use the guide's silent H.264, 1120×700, 60 fps settings and remain ignored by Git.

The unchanged upstream documentation gate still reports the three missing wiki pages and sidebar links above. No upstream PR has been submitted.

## Mini launcher layout

Mini now offers up to five recent results or search suggestions. The Open/Close hint row is removed. A divider separates the results from a 64-point header, whose search field uses its natural text height to center the placeholder, typed text and caret with the icon. Startup and empty-state messages occupy the list area.

A broad 32-point shadow extends outside the visible panel through a noninteractive child window. Its transparent center preserves the panel's appearance. The shadow follows resizing, cannot take focus or mouse input, and closes with the launcher. Its window allows the shadow padding beyond the screen edge so the menu bar does not shift it downward.

- `make` and `make test-quick-browse` pass without compiler warnings. New fixtures check five-choice limits for recents and search, keyboard bounds, all five rows fitting, header alignment, empty states, the fixed top-right anchor, screen-edge shadow alignment and cleanup after opening a result.
- The installed build passes all 34 native scenarios with sidebar tabs and all 34 with top tabs. Reports are `build/test-sidebar-mini-layout.json` and `build/test-top-mini-layout.json`; neither has unavailable patches or safe mode.
- Native checks confirm five recent choices, five typed suggestions, centered placeholder and typed text, the divider, and the larger aligned shadow in both layouts. Repeated Down stops at the fifth suggestion; Escape dismisses Mini.
- Static proof stays local: `build/proof/mini-launcher-before.png`, `build/proof/mini-launcher-sidebar-after.png`, `build/proof/mini-launcher-typed-after.png` and `build/proof/mini-launcher-top-after.png`. Review browsing history before attaching these ignored screenshots to a PR.

The unchanged documentation gate still reports the same three missing upstream wiki pages and sidebar links. No patch key or upstream PR is added by this change.
