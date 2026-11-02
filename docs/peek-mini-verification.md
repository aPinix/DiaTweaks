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

## Command Bar and shared site search

Added an independent Command Bar patch with a default ⌘K binding and the same recorder/reset control as Mini. It opens regular foreground tabs in the source window/profile. Both launchers support Tab-to-site-search, provider badges, provider-specific recent queries and native keyword suggestions. YouTube uses a red badge and selection. A disabled provider stays disabled; unsupported native template macros are left to Chromium instead of becoming literal navigation URLs.

Compared Command Bar and Little Arc directly in Arc 1.171.0. Both now use native suffix-completion metadata, preview normal keyboard selections in the input while preserving the original ranking query, retain scoped input while selecting queries, restore the site address on empty Backspace, and leave a scope for empty normal input on Escape before a second Escape dismisses. Deleting a selected suffix suppresses its immediate return. Fixtures cover input-method composition and asynchronous replacement of completed results.

- `make` and the final `make test-quick-browse` pass without compiler warnings. Fixtures include scoped URL encoding/history, profile isolation, stale callbacks, input completion and deletion, shortcut persistence/conflicts, Mini/Command Bar mode changes, native ownership when adoption hides the palette, and stale/closed tab identity.
- Installed with `./install.sh` in the existing `/Applications/Dia.app`, using its existing profile. The installed and built dylib digests match. Native Dia 1.56.0 (89901) passes all 36 scenarios in each layout with no failures, unavailable patches or safe mode. Reports: `build/test-sidebar-command-bar.json` (`vertical`) and `build/test-top-command-bar.json` (`horizontal`). All browser windows were saved in the target layout before the horizontal run because the upstream layout detector searches every window.
- Native checks cover URL and ordinary-query navigation, YouTube scoped navigation, empty and populated source windows, and real rendered pages. “Switch to Tab” activates an inactive existing page without changing the tab count. Mini opens its query in a compact page, and scoped recent queries appear in both launchers after reopening and restarting Dia.
- Recorded ⌘T in the actual shortcut control, restarted Dia, and confirmed the saved binding opens this Command Bar. Disabling the patch restored native ⌘T. Reset restored ⌘K. Command Bar also opened with Mini disabled. Mini’s default remains ⌥⌘N.
- Local proof: `build/proof/command-bar-initial-flow.mp4`, `build/proof/horizontal-command-bar.mp4`, `build/proof/command-bar-site-search-after.png`, `build/proof/command-bar-shortcut-custom.png` and `build/proof/mini-site-search-final.png`. Videos use silent H.264 at 1120×700 and 60 fps. Media stays ignored and local; review browsing history before attaching it to a PR.

The disposable test windows were removed. Sidebar tabs and the original auto-hide setting were restored and saved, and Dia was reopened normally. No upstream PR was submitted.

This reconstructs the observed navigation/input flow, not every Arc command or ranking rule. Suggestions use Dia’s profile and autocomplete. Switching covers tracked, initialized web tabs in the current window/profile, excluding dormant session-only tabs, Mini and Peek. Private-window and second-profile coverage remains a native manual check; fixtures enforce source isolation.

The unchanged upstream documentation checker now reports four missing maintainer wiki pages and sidebar links: Peek, Dia Mini, Open external links in Dia Mini, and Command Bar. Local notes and proof do not bypass that gate.

## Visible Peek entrance after first paint

The opening transform was correct, but its 200 ms animation could finish while Chromium's new host was still transparent. The page then appeared at full size. Dismissal already had painted content, so its return to the saved click point remained visible.

Peek now keeps that empty card invisible and waits for ArcCore's `isReadyToDisplay` signal and a web URL before starting the existing entrance. The backdrop still responds immediately. The card is laid out before the transform is calculated, and closing or transferring it cancels the pending readiness timer. The transparent clipping background, closing curve and Reduce Motion behavior stay intact.

- `make` and `make test-quick-browse` pass without compiler warnings. New fixtures delay first paint beyond the whole entrance, then check a fresh full-duration growth from the original click; closing before readiness cannot resurrect the card or its controls. A separate first-display check maps the original seed through the rendered AppKit hierarchy.
- Installed and checked in the existing Dia 1.56.0 (89901). All 36 native scenarios pass in sidebar mode and all 36 in top-tab mode, with no unavailable patches or safe mode. Reports: `build/test-sidebar-peek-opening.json` and `build/test-top-peek-opening.json`.
- Native frame-by-frame review shows growth from an upper Apps link in sidebar mode and a lower release-heading link with top tabs. The previous recording showed the backdrop animate before the page appeared at its final size.
- Local, ignored proof: `build/proof/peek-opening-before.mp4`, `build/proof/peek-opening-sidebar-after.mp4` and `build/proof/peek-opening-top-after.mp4`, encoded as silent H.264 at 1120×700 and 60 fps. Captures use disposable public-page windows.

The unchanged documentation gate still needs the four maintainer wiki pages and sidebar links listed above. No upstream PR has been submitted.

## Mini browser toolbar and owned Command Bar

Compared the actual Little Arc window in Arc 1.171.0 with the supplied references. Mini now uses a compact native unified toolbar: native traffic lights, a 30-point address pill with centered domain and loading indicator, copy link and a split Open in Dia control. The browser body fills the content view. Its initial outer frame is 1280×950, clamped to the active screen.

Clicking the address or pressing ⌘L selects the complete current URL in a 500-point palette inside Mini. ⌘T opens an empty palette; the configured Command Bar shortcut and File command route there too. Return navigates the existing native web contents. The global Mini shortcut keeps its separate top-right launcher. The owned palette dims only the page body, tracks resizing, and removes its scrim, shadow and observers when dismissed or when Mini closes. Mini's fixed navigation and close chords are reserved by the shortcut recorders.

Open in Dia transfers the live page to the selected same-profile browser window. The original source is the default; a searchable picker offers other available windows. A rejected adoption reattaches the same page to Mini, while a confirmed adoption leaves ownership with Dia. Mini keyboard actions are consumed during that ownership transition. Destination-popup dismissal finishes before opening the palette so its key-window transition cannot dismiss the new input.

A read-only native probe confirmed that `ArcBrowser.context` returns distinct Objective-C wrappers for the same original browser. Profile checks accept the immutable original factory or the exact context, and match other regular windows through `ArcBrowserContextID.directoryBasename`. Separate private contexts are not matched by directory, even when both report incognito. Fixtures cover wrapper replacement, other profile directories and regular/private isolation.

Arc's extension button targets tracked main-browser tabs through Dia's shipped API, so Mini does not expose a button that could operate on an unrelated tab. Arc Spaces are represented by same-profile Dia windows. Private-window and second-profile native coverage remains a manual check; the fixtures reject cross-profile destinations.

- `make` and `make test-quick-browse` pass without compiler warnings. Added fixtures cover native toolbar geometry, profile identity, live adoption and rollback, Mini-owned input routing, reserved chords, destination-popup keys and palette cleanup.
- Installed through `./install.sh` in the existing Dia 1.56.0 (89901). The installed and built dylib SHA-256 digests match (`03a467c5df3404a7a58de18e458bd77c71a49704c17d0cd2c55915a73e0906ba`). All 36 native scenarios pass in each layout, without unavailable patches or safe mode. Reports: `build/test-sidebar-mini-browser.json` (`vertical`) and `build/test-top-mini-browser.json` (`horizontal`).
- Native checks confirm ⌘L selects the full URL, ⌘T and ⌘K open an empty Mini-owned palette, the File command uses that same route, site search navigates the existing Mini, and scoped Escape leaves the scope before dismissal. ⌥⌘N replaces an owned palette with the separate global launcher. Two successive ⌘W actions dismiss the palette and then Mini, preserving the original main tabs.
- The picker moved a live Mini page into a second, initially empty Dia window. ⌘O moved another page back into its source window; its earlier navigation history still worked afterward. At a native 960-point width the toolbar controls remain visible and the address palette stays centered.
- Local ignored proof: `build/proof/mini-browser-before.png`, `build/proof/mini-browser-sidebar-after.png`, `build/proof/mini-browser-command-after.png`, `build/proof/mini-browser-top-narrow-after.png`, and `build/proof/mini-browser-flow-after.mp4`. The recording uses silent H.264 at 1120×700 and 60 fps and was reviewed through extracted frames. macOS's active capture badge can temporarily cover the native traffic lights. Review history before uploading media.

All disposable Mini and regular test windows were closed. The original two main tabs, sidebar layout and auto-hide setting were preserved, saved with a normal quit, and reopened without test mode or the temporary diagnostic probe. The documentation gate still needs the same four maintainer wiki pages and sidebar links. No upstream PR was submitted.
