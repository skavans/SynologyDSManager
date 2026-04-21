# Changelog

All notable changes to SynologyDSManager are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
from `v2.0.0` onward.

Entries are grouped under **Added / Changed / Deprecated / Removed / Fixed /
Security**. Add new user-visible changes under `## [Unreleased]` in the same
commit that makes them.

## [Unreleased]

### Added
- `CLAUDE.md` — orientation file for future AI-assisted work on the repo,
  now including a *Public-repo best practices* section (secrets handling,
  log redaction, release/signing rules) and a *Code signing* section.
- `MODERNIZATION_PLAN.md` — phased roadmap with a per-phase task checklist
  that is kept up to date as work lands.
- `CHANGELOG.md` (this file).
- `deploy.sh` — interactive single-key maintainer menu:
  - `p` pull `main` from origin into local `main`
  - `o` open in Xcode
  - `s` configure signing (writes `Signing.local.xcconfig`)
  - `i` build Release and install to `/Applications`
  - `d` build Release and produce a signed (and, if credentials are
        configured, notarised) DMG
- `Signing.xcconfig` + `Signing.local.xcconfig.template` — xcconfig cascade
  that keeps Apple Developer Team IDs out of the public repo. The local
  override is gitignored and is wired as `baseConfigurationReference` on
  both project-level build configurations, so Xcode GUI builds and
  `xcodebuild` both pick up the Team ID automatically.
- Gitignore entries for `Signing.local.xcconfig`, `.notary-profile-name`,
  `build/`, `dist/`, and `.DS_Store`.
- GitHub Actions CI workflow (`build`, `SwiftLint`, `SwiftFormat --lint`).
- `CODEOWNERS`, PR template, and bug / feature / security issue templates.
- `.swiftlint.yml`, `.swiftformat`, `.swift-version` — initial lint/format
  baseline. CI enforcement is non-blocking until the repo is reformatted.
- One-time `UNUserNotificationCenter` authorisation request on launch so
  download-finished / download-started alerts still appear under the
  non-deprecated notification API.

### Changed
- Minimum supported macOS raised from 10.13 (High Sierra) to 13 (Ventura).
- Xcode project format bumped: `objectVersion` 52 → 56, `compatibilityVersion`
  Xcode 9.3 → Xcode 14.0, `LastUpgradeCheck` / `LastSwiftUpdateCheck` →
  1520 (Xcode 15.2). `BuildIndependentTargetsInParallel` enabled.
- Replaced `@NSApplicationMain` with `@main` (the old attribute is deprecated
  in Swift 5.3+).
- Replaced `NSUserNotification` + `NSUserNotificationCenter` (deprecated
  since macOS 10.14) with `UNUserNotificationCenter` + `UNNotificationRequest`.
- Replaced `NSOpenPanel.allowedFileTypes` (deprecated since macOS 12) with
  `allowedContentTypes: [UTType]`.
- Replaced `protocol LoadableView: class` with the non-deprecated
  `: AnyObject`.
- Enabled `SWIFT_STRICT_CONCURRENCY = minimal` on both configurations, a
  stepping-stone toward `complete`.
- `README.md` rewritten for the maintained-fork state, linking the new
  `CLAUDE.md` / `MODERNIZATION_PLAN.md` / `CHANGELOG.md`.
- Marketing version bumped to `2.0.0` to signal the modernisation break;
  CFBundleShortVersionString will stay on `2.0.0-dev` until a Phase 5 release
  is cut.

### Removed
- Stale `DEVELOPMENT_TEAM = GVS9699BGK` (the previous maintainer's Apple
  team) from both targets' build configurations. The current developer's
  Team ID is now supplied via the gitignored `Signing.local.xcconfig`.
- Target-level hard-coded `CODE_SIGN_IDENTITY = "Apple Development"`, so the
  xcconfig's conditional identity (Apple Development for Debug, Developer ID
  Application for Release) wins.
- Dead `FRAMEWORK_SEARCH_PATHS` entries referencing a non-existent
  `Sparkle Updater` directory.
- Unused `StoreKit.framework` reference (leftover from the paid-app IAP
  flow, which was never shipped in the open-source version).
- `xcuserdata/` directories are no longer tracked (already ignored by
  `.gitignore`; had been committed before the ignore rule landed).

### Security
- Removed the blanket `NSAllowsArbitraryLoads = true` from the main app's
  `Info.plist`. The app now honours App Transport Security defaults (HTTPS,
  TLS 1.2+, forward secrecy). The narrower `localhost` exception in the
  Safari extension is kept for now and will be removed together with the
  loopback HTTP bridge in Phase 3.

### Notes for users upgrading
- If your NAS is reachable only via HTTP or weak TLS, connections will now
  fail. Proper self-signed-cert / SPKI-pinning handling lands in Phase 2;
  until then, prefer an HTTPS DSM setup with a TLS 1.2+ cert.
- You will need to re-enter your Apple Developer team on first build.

---

## Historical

Everything before this fork was maintained at
[`skavans/SynologyDSManager`](https://github.com/skavans/SynologyDSManager)
and shipped up to `v1.4.2` (main app) / `v1.2.1` (Safari extension).
No further entries are planned for versions before the 2026 fork.
