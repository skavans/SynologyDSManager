# Modernisation plan

Living document. Tick boxes as tasks land. When all tasks in a phase are
complete, move the phase status from **In progress** / **Planned** to
**Shipped** with the date.

Last updated: 2026-04-21

---

## Phase 0 — Project hygiene · **In progress**

Goal: a clean, lintable, CI-backed baseline for everything that follows.

- [x] Remove `xcuserdata` from version control (`git rm -r --cached`)
- [x] Bump `objectVersion` (52 → 56), `compatibilityVersion` (Xcode 9.3 →
      Xcode 14.0), `LastUpgradeCheck` (1130 → 1520)
- [x] Remove stale `DEVELOPMENT_TEAM = GVS9699BGK` from both targets' build
      configs
- [x] Remove dead `FRAMEWORK_SEARCH_PATHS` entries referencing an absent
      `Sparkle Updater` directory
- [x] Remove unused `StoreKit.framework` reference (was left over from the
      paid-app IAP)
- [x] Tighten the Alamofire package pin (was `5.0.0-rc.3`) — stopgap until
      Phase 2 removes Alamofire entirely
- [x] Add `.swiftlint.yml`, `.swiftformat`, `.swift-version`
- [x] Add a GitHub Actions CI workflow (build + lint + format check)
- [x] Add `CODEOWNERS`, PR template, bug-report / feature-request /
      security-report issue templates
- [x] Rewrite `README.md` for the forked, maintained state
- [x] Add `CLAUDE.md`, `MODERNIZATION_PLAN.md`, `CHANGELOG.md`
- [ ] Flip SwiftLint / SwiftFormat CI jobs to blocking once the repo is
      fully formatted (follow-up PR)

## Phase 1 — Platform baseline · **In progress**

Goal: compile cleanly against modern Xcode on a modern macOS deployment
target, replacing the deprecated APIs we can do without further design work.

- [x] Raise `MACOSX_DEPLOYMENT_TARGET` 10.13 → 13.0 (both targets)
- [x] Remove blanket `NSAllowsArbitraryLoads = true` from the main
      `Info.plist`
- [x] Replace `@NSApplicationMain` with `@main` in `AppDelegate`
- [x] Replace `NSUserNotification` + `NSUserNotificationCenter` with
      `UNUserNotificationCenter` + `UNNotificationRequest` (incl. a single
      authorisation request on launch)
- [x] Replace `NSOpenPanel.allowedFileTypes` (deprecated) with
      `allowedContentTypes: [UTType]`
- [x] Fix `protocol LoadableView: class` → `AnyObject`
- [x] Enable `SWIFT_STRICT_CONCURRENCY = minimal` (will be bumped to
      `complete` after Phase 2)
- [ ] Remove the dead `registerEvent(…)` analytics stub — blocked until the
      networking rewrite touches every call site (Phase 2)
- [ ] Remove the `swiftapps.skavans.ru` mailto and `synoboost.com` link from
      Settings / BT Search — Phase 4 when we rewrite those screens

## Phase 2 — Networking & storage rewrite · **Planned**

Goal: no Alamofire, no SwiftyJSON, typed models, proper TLS, properly
scoped Keychain access.

- [ ] Introduce a `SynologyAPI` actor backed by `URLSession` + `async/await`
- [ ] Define `Codable` models for DSM responses, replacing ad-hoc
      `JSON()` access
- [ ] Replace `DisabledEvaluator()` with opt-in SPKI pinning of the NAS's
      leaf certificate; on first connect, show the user the cert fingerprint
      and ask them to trust
- [ ] Move `_sid` out of URL query strings (use the DSM cookie jar, and/or
      a session header); purge `print(response)` debug lines
- [ ] Replace KeychainAccess with a small wrapper around `SecItem*`,
      `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; stop persisting the SID
- [ ] Remove SwiftyJSON from `Package.resolved` / project
- [ ] Remove Alamofire from `Package.resolved` / project
- [ ] Add a `SynologyDSManagerTests` target with `URLProtocol`-based fake
      transports for the API
- [ ] Delete the `registerEvent(…)` stub
- [ ] Replace remaining `print(…)` sites with `os.Logger`
- [ ] Flip `SWIFT_STRICT_CONCURRENCY` to `complete`

## Phase 3 — Safari extension & webserver bridge · **Planned**

Goal: no unauthenticated local listener; no deprecated Safari App
Extension.

- [ ] Add a new **Safari Web Extension** target (MV3 manifest + JS service
      worker + native messaging host)
- [ ] Implement `NSXPCConnection` between the native messaging host and the
      main app; define a small `@objc` protocol (`enqueueDownload(URL:)`)
- [ ] Delete `Webserver.swift` and drop the `Swifter` package
- [ ] Delete the `synologydsmanager://download` URL-scheme fallback in the
      Safari extension (or lock it down to a launch-agent-signed token)
- [ ] Remove the `localhost` ATS exception and `network.server` entitlement
      once the webserver is gone
- [ ] Update the Chrome extension (if kept) to use the same MV3 +
      native-messaging shape

## Phase 4 — SwiftUI rewrite · **Planned**

Goal: storyboards out, SwiftUI in — screen by screen, behind
`NSHostingController` so we can ship as we go.

- [ ] Lift shared state into an `@Observable` app model; retire the global
      singletons in `Shared.swift`
- [ ] Port screens in this order: Settings → About → Add Download →
      BT Search → Choose Destination → Downloads list
- [ ] Replace the status item with `MenuBarExtra`
- [ ] Replace PNG toolbar icons with SF Symbols
- [ ] Delete `Main.storyboard` and all `.xib` files when the last screen
      has been ported
- [ ] Add localisation scaffolding (`String Catalog`), starting with English

## Phase 5 — Release engineering · **Planned**

Goal: signed, notarised, auto-updating releases cut by CI.

- [ ] Add Sparkle 2 with an EdDSA-signed appcast hosted on GitHub Pages or
      Releases
- [ ] Notarisation script + `xcrun stapler` step
- [ ] GitHub Action that on tag-push builds, signs, notarises, and attaches
      the DMG to a Release
- [ ] Cut a clean `v2.0.0` release

---

## Post-modernisation feature ideas (not started)

_Maintained here so they don't get lost. Promote to issues once Phase 4 is
shipping._

- Multi-NAS profiles with per-profile credentials
- App Intents / Shortcuts support ("Download this URL on the NAS…")
- Drag-and-drop of magnet links or `.torrent` files onto the status icon
- Richer search: pluggable providers, filter by min seeds / size
- Companion iOS app sharing the same Swift package for the API client
- Optional Touch Bar / trackpad gestures for pause/resume (if any user still
  has a Touch Bar in 2026)

---

## How to update this document

- Tick a checkbox the same commit that lands the change.
- When every checkbox in a phase is ticked, change the phase status to
  `Shipped · YYYY-MM-DD` and mention it in `CHANGELOG.md`.
- New work that doesn't fit an existing phase goes under **Post-modernisation
  feature ideas** with a one-line description, not a sub-heading.
