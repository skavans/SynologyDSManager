# SynologyDSManager

A native macOS app (and Safari extension) for managing a Synology DownloadStation remotely.

This is a maintained fork of the original [skavans/SynologyDSManager](https://github.com/skavans/SynologyDSManager),
which was archived in 2023. Goals of the fork:

- modernise the codebase (SwiftUI, Swift concurrency, current macOS APIs)
- run a full security audit and fix the outstanding issues
- add new features after the modernisation baseline is in place

See [`MODERNIZATION_PLAN.md`](./MODERNIZATION_PLAN.md) for the phased roadmap and
[`CHANGELOG.md`](./CHANGELOG.md) for a running list of changes.

## Features

- Browse, pause, resume, and delete Download Station tasks from a native Mac window
- Add new tasks from `.torrent` files, magnet links, or direct URLs — in bulk
- Pick any shared folder on the NAS as the download destination
- Search BT trackers directly from the app and enqueue results in one click
- Menu-bar status item with live bandwidth readout
- Safari extension: "Download with Synology DS Manager" from the page context menu
- 2-step verification (TOTP) supported

## Requirements

- macOS 13 (Ventura) or newer
- Xcode 15 or newer to build
- A reachable Synology DSM 6.2+ installation with Download Station installed

## Building

```sh
git clone https://github.com/lotech/synologydsmanager.git
cd synologydsmanager
open SynologyDSManager.xcodeproj
```

Set your own Apple Developer team in both targets' **Signing & Capabilities** tab
(the original project's team ID has been removed). Build the `SynologyDSManager`
scheme for macOS.

Swift Package dependencies are resolved automatically by Xcode. Current third-party
dependencies (being phased out — see Phase 2 of the plan):

- Alamofire
- SwiftyJSON
- KeychainAccess
- Swifter

## Project layout

```
SynologyDSManager/            # Main macOS app target
  AppDelegate.swift
  SynologyClient.swift        # DSM API client (to be rewritten in Phase 2)
  Settings.swift              # Keychain-backed credential store
  Webserver.swift             # Local HTTP bridge (to be removed in Phase 3)
  ViewControllers/            # Cocoa controllers (to be ported to SwiftUI in Phase 4)
  Base.lproj/Main.storyboard

SynologyDSManager Extension/  # Legacy Safari App Extension (to be migrated in Phase 3)
```

## Contributing

Issues and PRs are welcome. Please read [`CLAUDE.md`](./CLAUDE.md) for a short
orientation to how the codebase is structured and the conventions we're moving
towards, and check [`MODERNIZATION_PLAN.md`](./MODERNIZATION_PLAN.md) to see where
your change fits.

## Security

Report security issues privately via GitHub Security Advisories rather than
public issues, especially anything involving credential handling, TLS, the local
HTTP bridge, or the Safari extension's URL-scheme fallback.

## Licence

MIT — see [`LICENSE`](./LICENSE). Original copyright © 2020–2023 skavans;
modernisation work © 2024–present contributors.
