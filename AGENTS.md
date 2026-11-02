# Working on this fork

Read and follow [CONTRIBUTING.md](CONTRIBUTING.md) for all implementation and upstream contribution work. [Fork contribution notes](docs/contributing-from-this-fork.md) identify distribution changes that must stay out of feature PRs.

- Prefer `apply_patch` for manual code changes.
- Keep each feature inside its folder under `src/dylib/Patches/`; put Dia class names in `StdPatch/Dia.h`.
- Keep implementation files around 100 lines, and use StdPatch registration, hooks, class checks, apply callbacks and view-based verification.
- Keep Peek and Dia Mini separate when preparing upstream PRs. Preserve the original Peek author's attribution.
- Preserve upstream checks. Report missing maintainer wiki pages or previews instead of bypassing the documentation gate.
- Before calling a visible change ready for a PR, build, install and test in the actual Dia app, check both tab layouts and on/off states, and capture the proof required by the PR template.
- Use lowercase Conventional Commit subjects under 72 characters, without generated attribution trailers. Never commit Dia's bundle or use someone else's signing certificate.
