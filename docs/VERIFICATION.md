# Verification

The source installer completed in disposable Fedora 44 and Debian 12 containers. It downloaded the official Replit 1.1.23 Linux package, verified its SHA-512 checksum and package size, checked runtime library dependencies, and installed the user launcher and desktop entry.

A separate host installation used paths containing spaces. Installer tests cover help, unknown options, unsafe roots, and rollback selecting a previous runtime rather than the active build. Desktop-entry validation passed.

The repository contains integration source and artwork, not the upstream application archive or an account profile. The working Replit installation was not replaced. Fresh interactive sign-in, coding prompts, and paid tasks were not exercised.

## Installer and documentation review, 2026-11-06

Fresh source installation completed on Fedora 44 and Debian 12. The four installer and rollback regression tests pass. The installation guide now lists Replit's own requirements without the unrelated Perplexity note.

Source secret scans, shell syntax, and local Markdown links passed. These checks used disposable installations and fixtures. Fresh interactive sign-in, paid requests, and full graphical acceptance were not repeated; existing account profiles were left in place.

## 1.0 release verification

Fresh source installation, the regression suite, desktop-entry validation, and clean-profile launch completed on Fedora 44 and Debian 13. Tests ran as an unprivileged user with isolated application, configuration, launcher, and data paths. Launcher paths included spaces.

Virtual display captures used container-only sandbox and software-rendering options; these options were not added to production launchers. Fresh browser consent, paid requests, real account persistence, and complete graphical workflows were not exercised.
