# Contributing from this fork

Follow [upstream's CONTRIBUTING.md](https://github.com/JaceThings/DiaTweaks/blob/main/CONTRIBUTING.md) and its [pull request template](../.github/pull_request_template.md).

## Scope

Open one PR per change. Keep Peek improvements separate from Dia Mini. Peek builds on Ryan's existing [PR #2](https://github.com/JaceThings/DiaTweaks/pull/2); retain that attribution and check its current status before proposing overlapping work.

Feature implementations belong in `src/dylib/Patches/Peek` and `src/dylib/Patches/DiaMini`. Dia class names belong in `StdPatch/Dia.h`. Use StdPatch hooks and registration, live apply callbacks, class availability checks and view-based verification. Keep implementation files around 100 lines.

The fork's release URLs, install README and Settings links to local feature docs are distribution changes. Exclude those from an upstream feature PR. The Carbon link dependency belongs with Dia Mini's global shortcut, not a Peek PR.

## Proof and checks

- Build with `make`, install with `./install.sh`, then run `make test` once with sidebar tabs and again with top tabs.
- Check each feature on and off. Verify normal browser behavior returns after disabling it.
- Run `make test-quick-browse` for the additional AppKit fixtures. These supplement real browser testing.
- Include a screenshot for static changes and a recording for animation. Show before and after for changed behavior. Keep unrelated browsing, accounts and desktop content out of uploaded proof.
- Fill in every PR template section and every applicable checklist item. Use `N/A` only where the template permits it; visible changes always require proof.

`scripts/check-tweak-docs` is the upstream checker. New feature pages and preview media are maintained by the upstream maintainer before merge. Local feature notes are useful review material, but do not replace that wiki requirement or make the gate pass. Report a missing wiki page honestly.

Use lowercase Conventional Commit subjects under 72 characters, without generated attribution trailers. Commit source and proof only; never commit Dia's app bundle or sign with another person's certificate.
