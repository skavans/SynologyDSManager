# CLAUDE.md

Orientation file for future Claude Code sessions working on this repo. If you're a
human, `README.md` is a better starting point.

## Project at a glance

- **Product**: native macOS app + Safari extension that drives a Synology NAS's
  Download Station over its HTTP API.
- **Language / UI**: Swift 5.9, AppKit + Storyboards (plus one XIB-based
  `NSTableCellView`). No SwiftUI yet — moving there in Phase 4 of the plan.
- **Min OS**: macOS 13 (raised from 10.13 in the Phase 1 modernisation).
- **Build system**: Xcode project (`SynologyDSManager.xcodeproj`), SwiftPM for
  dependencies. No `Package.swift`, no CocoaPods.
- **Targets**:
  - `SynologyDSManager` — main app
  - `SynologyDSManager Extension` — legacy Safari App Extension (deprecated
    format; migration to Safari Web Extension scheduled in Phase 3)

## Core files (main target)

| File | Role |
|---|---|
| `AppDelegate.swift` | `@main` entry point, handles URL-scheme deep links and `.torrent` file opens. |
| `SynologyClient.swift` | DSM API client. Currently uses Alamofire + SwiftyJSON — being rewritten in Phase 2 to `URLSession` + `async/await` + `Codable`. |
| `Settings.swift` | Credential persistence via KeychainAccess. Target-state wraps `SecItem*` directly with proper accessibility flags. |
| `Shared.swift` | Global mutable singletons (`synologyClient`, `mainViewController`, `currentViewController`). To be removed when we adopt Observation in Phase 4. |
| `Webserver.swift` | Loopback HTTP server on port 11863 used by the Safari extension to enqueue downloads. **Unauthenticated** — scheduled for removal in Phase 3 in favour of `NSXPCConnection`. |
| `ViewControllers/` | Cocoa view controllers, one per screen. |
| `DestinationView.swift`, `DownloadsCellView.swift`, `LoadableView.swift` | Custom `NSView` subclasses loaded from XIB. |

## Conventions (target-state)

- **No `print` for diagnostics** — use `os.Logger` with a subsystem of
  `com.skavans.synologyDSManager`.
- **No force-unwraps / force-tries** on network data. Validate at system
  boundaries, propagate typed errors upward. SwiftLint is configured to warn
  on `!` and `try!` (`force_unwrapping`, `force_try`).
- **No SwiftyJSON in new code** — use `Codable`. Existing SwiftyJSON use is
  being removed incrementally; do not introduce new call sites.
- **No Alamofire in new code** — use `URLSession` with `async/await`.
- **Keychain access** must use `.whenUnlockedThisDeviceOnly` accessibility at
  minimum. Never persist session IDs across launches.
- **TLS**: no `DisabledEvaluator`. Self-signed NAS certs are handled via
  explicit, user-confirmed SPKI pinning (Phase 2 design).
- **Logging**: never log passwords, OTP codes, session IDs, or full request
  URLs containing `_sid`.

## Commands

Most day-to-day maintainer tasks go through the interactive helper:

```sh
./deploy.sh
```

…which offers single-key options for pulling `main`, opening in Xcode,
configuring signing, installing to `/Applications`, and building a
distributable DMG (optionally notarised). See the top of `deploy.sh` for the
key bindings. Underneath, the script just calls the commands below.

```sh
# Resolve Swift Package dependencies headlessly:
xcodebuild -project SynologyDSManager.xcodeproj \
  -scheme SynologyDSManager \
  -resolvePackageDependencies

# Build (unsigned) from the command line — CI uses this exact invocation:
xcodebuild -project SynologyDSManager.xcodeproj \
  -scheme SynologyDSManager \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

# Lint:
swiftlint

# Format check:
swiftformat --lint .
```

There are **no automated tests yet**. A test target is added in Phase 2
alongside the networking rewrite.

## Code signing

Signing is driven by an **xcconfig cascade** so no Team ID ever lands in the
public repo:

- `Signing.xcconfig` (committed, no secrets) — defines defaults:
  `Apple Development` for Debug, `Developer ID Application` for Release,
  `CODE_SIGN_STYLE = Automatic`, and a trailing `#include? "Signing.local.xcconfig"`.
- `Signing.local.xcconfig` (gitignored, per-developer) — sets the single
  variable that matters: `DEVELOPMENT_TEAM`.
- `Signing.local.xcconfig.template` (committed) — the file maintainers copy
  to create their own `Signing.local.xcconfig`.

The xcconfig is wired as `baseConfigurationReference` on the project-level
build configurations, so both Xcode GUI builds and `xcodebuild` from the
command line pick it up automatically.

**Do not** re-introduce `DEVELOPMENT_TEAM = …` in `project.pbxproj`,
hard-code a specific identity name, or commit `Signing.local.xcconfig`.

To set up a new maintainer machine: run `./deploy.sh` → `s`.

## Public-repo best practices

This repo is public. Every commit, every issue, every CI log is world-readable.
When in doubt, leak nothing.

**Never commit:**
- Apple Developer Team IDs, provisioning profiles, `.p12`/`.cer` files, App
  Store Connect API keys, notarisation credentials. `Signing.local.xcconfig`
  and `.notary-profile-name` are already gitignored — keep them that way.
- `.env` files, SSH keys, AWS/GCP tokens, Slack/Discord webhooks.
- `xcuserdata/`, `DerivedData/`, `.DS_Store`, editor-local configs.
- Real Synology NAS credentials, even in test fixtures. Use obvious
  placeholders (`user@example.com`, `ABCDE12345`).

**When logging, screenshotting, or pasting into issues:**
- Redact `_sid=…`, cookies, `Authorization` headers, session IDs, and any
  query string that might contain a password or OTP.
- Redact LAN IPs, DDNS hostnames, and QuickConnect IDs — they identify a
  specific user's NAS.
- Sample issue-tracking stance: if the issue template doesn't have a redaction
  reminder, add one before merging the template change.

**When accepting contributions:**
- Review diffs for hard-coded secrets before approving PRs. GitHub's
  secret-scanning catches a lot but not everything.
- Pin third-party GitHub Actions by commit SHA, not by tag. Tags are
  mutable; SHAs are not.
- Prefer SwiftPM dependencies that are themselves open-source and actively
  maintained. Commit `Package.resolved` so CI reproduces exact versions.
- Never run `curl | sh` in CI or in any script we ship.

**Releases:**
- Tag releases (`v2.0.0`, `v2.1.0`, …) and cut them through GitHub Releases,
  not by pushing binaries directly to `main`.
- Sign *and* notarise distribution builds before attaching them to a release.
  An unsigned `.app` off GitHub will trigger Gatekeeper prompts on every user
  machine.
- Never force-push `main`. Never skip commit hooks (`--no-verify`) unless the
  hook itself is broken and you're fixing it in the same PR.

**Security disclosures:**
- Accept reports via GitHub Security Advisories (private), not public issues.
- Keep a brief `SECURITY.md` policy at the repo root (planned as a Phase 0
  follow-up).

## How to land a change

1. Work on a feature branch; never push directly to `main`.
2. Add a bullet under `## [Unreleased]` in `CHANGELOG.md` describing the
   user-visible effect (not the mechanical diff).
3. If the change affects or completes a task from `MODERNIZATION_PLAN.md`,
   tick the corresponding checkbox and update the phase status if all tasks
   in the phase are done.
4. Open a PR against `main` using the template.
5. CI runs build + SwiftLint + SwiftFormat check (the lint/format jobs are
   non-blocking today — they become blocking once the repo is fully
   formatted, tracked as a Phase 0 follow-up task).

## Important security notes to remember

- The loopback webserver in `Webserver.swift` is **unauthenticated** and
  accepts any local POST. Do not extend it — prefer XPC.
- The `synologydsmanager://` URL scheme is trusted by `AppDelegate` without
  validation. Do not widen what it accepts until Phase 3.
- `SynologyClient` currently ships credentials/SIDs in URL query strings;
  don't add new call sites that follow this pattern.

## Where the modernisation plan lives

[`MODERNIZATION_PLAN.md`](./MODERNIZATION_PLAN.md) — phased roadmap with a
checklist per phase. Keep it up to date as work lands.
