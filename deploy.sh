#!/usr/bin/env bash
#
# deploy.sh — interactive helper for SynologyDSManager maintainers.
#
# Run from the repo root:  ./deploy.sh
# Options are single-key; no Enter required.
#
#   p   Pull `main` from origin into local `main`
#   o   Open the Xcode project
#   s   Configure code signing (creates Signing.local.xcconfig from template)
#   i   Build Release and install to /Applications
#   d   Build Release and create a distributable DMG (optionally notarised)
#   q   Quit
#
# Requires macOS with Xcode command-line tools installed. The build/install/DMG
# options also require a filled-in `Signing.local.xcconfig` with your Apple
# Developer Team ID — use the `s` option to set it up the first time.
#
set -euo pipefail

# Must run from the repo root (where this script lives).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ----- Constants -----------------------------------------------------------
readonly PROJECT="SynologyDSManager.xcodeproj"
readonly SCHEME="SynologyDSManager"
readonly APP_NAME="SynologyDSManager.app"
readonly SIGNING_XCCONFIG="Signing.xcconfig"
readonly LOCAL_XCCONFIG="Signing.local.xcconfig"
readonly LOCAL_XCCONFIG_TEMPLATE="Signing.local.xcconfig.template"
readonly BUILD_DIR="build"
readonly DERIVED_DATA="${BUILD_DIR}/DerivedData"
readonly DIST_DIR="dist"

# ----- Colours -------------------------------------------------------------
if [[ -t 1 ]]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
    YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

info()  { echo "${BLUE}==>${RESET} $*"; }
ok()    { echo "${GREEN}✓${RESET}  $*"; }
warn()  { echo "${YELLOW}!${RESET}  $*" >&2; }
err()   { echo "${RED}✗${RESET}  $*" >&2; }
fatal() { err "$*"; exit 1; }

pause() { printf "\n${DIM}Press any key to return to the menu…${RESET}"; read -rsn1 _; echo; }

# ----- Sanity checks -------------------------------------------------------

require_macos() {
    [[ "$(uname)" == "Darwin" ]] || fatal "deploy.sh must be run on macOS (detected: $(uname))."
}

require_xcodebuild() {
    command -v xcodebuild >/dev/null 2>&1 \
        || fatal "xcodebuild not found. Install Xcode and run 'xcode-select --install'."
}

# Read DEVELOPMENT_TEAM from Signing.local.xcconfig, return empty if missing.
read_team_id() {
    if [[ ! -f "$LOCAL_XCCONFIG" ]]; then
        echo ""
        return
    fi
    # Grab the RHS of the first `DEVELOPMENT_TEAM =` line, trim whitespace.
    sed -nE 's/^[[:space:]]*DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*([^[:space:]/]+).*/\1/p' \
        "$LOCAL_XCCONFIG" | head -n1
}

require_signing_configured() {
    local team
    team="$(read_team_id)"
    if [[ -z "$team" || "$team" == "YOUR_TEAM_ID_HERE" ]]; then
        warn "Code signing is not configured yet."
        warn "Run the 's' menu option first, or edit $LOCAL_XCCONFIG directly."
        return 1
    fi
    echo "$team"
}

# Read MARKETING_VERSION from the main target's Release config in pbxproj.
read_marketing_version() {
    sed -nE 's/.*MARKETING_VERSION = ([0-9A-Za-z._-]+);.*/\1/p' \
        "${PROJECT}/project.pbxproj" | head -n1
}

# ----- Actions -------------------------------------------------------------

action_pull_main() {
    info "Fetching origin/main and fast-forwarding local main…"
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"

    # Warn about uncommitted changes; don't touch them.
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "You have uncommitted changes on '${current_branch}'. They will be left alone."
    fi

    git fetch origin main

    if [[ "$current_branch" == "main" ]]; then
        # On main: fast-forward-only pull.
        if git pull --ff-only origin main; then
            ok "Local 'main' is now up to date with origin/main."
        else
            err "Fast-forward pull failed. Resolve the divergence manually."
            return 1
        fi
    else
        # Not on main: fast-forward local 'main' ref without switching branches.
        # This errors out cleanly if a fast-forward isn't possible.
        if git fetch origin main:main; then
            ok "Local 'main' updated from origin/main (you stayed on '${current_branch}')."
        else
            err "Could not fast-forward local 'main'. Check out 'main' and resolve manually."
            return 1
        fi
    fi
}

action_open_xcode() {
    info "Opening ${PROJECT} in Xcode…"
    open "${PROJECT}"
    ok "Xcode launched."
}

action_configure_signing() {
    info "Configuring local code signing."

    if [[ -f "$LOCAL_XCCONFIG" ]]; then
        local existing
        existing="$(read_team_id)"
        if [[ -n "$existing" && "$existing" != "YOUR_TEAM_ID_HERE" ]]; then
            ok "Signing already configured (Team ID: ${existing})."
            printf "Overwrite? [y/N] "
            read -rsn1 reply
            echo
            [[ "$reply" =~ ^[Yy]$ ]] || { info "Leaving existing config untouched."; return 0; }
        fi
    fi

    if [[ ! -f "$LOCAL_XCCONFIG_TEMPLATE" ]]; then
        fatal "$LOCAL_XCCONFIG_TEMPLATE is missing — the repo is in an unexpected state."
    fi

    printf "Enter your 10-character Apple Developer Team ID: "
    local team_id
    read -r team_id
    team_id="$(echo "$team_id" | tr -d '[:space:]')"

    if [[ ! "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
        err "That doesn't look like a valid Team ID (expected 10 uppercase alphanumerics)."
        return 1
    fi

    # Copy template, then substitute. Use a sed expression safe for
    # alphanumerics (no metacharacters expected).
    cp "$LOCAL_XCCONFIG_TEMPLATE" "$LOCAL_XCCONFIG"
    sed -i.bak -E "s/^DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = ${team_id}/" "$LOCAL_XCCONFIG"
    rm -f "${LOCAL_XCCONFIG}.bak"

    ok "Wrote ${LOCAL_XCCONFIG} with Team ID ${team_id}."
    ok "(${LOCAL_XCCONFIG} is gitignored — it will not be committed.)"

    info "Tip: if you want to notarise DMGs, also create a notarytool keychain profile:"
    echo "    xcrun notarytool store-credentials \"SynologyDSManager-Notary\" \\"
    echo "        --apple-id \"you@example.com\" \\"
    echo "        --team-id \"${team_id}\" \\"
    echo "        --password \"<app-specific-password>\""
    echo "    echo SynologyDSManager-Notary > .notary-profile-name"
}

# Build Release into DerivedData. Echoes the path to the built .app.
_build_release() {
    local team="$1"
    mkdir -p "$BUILD_DIR"

    info "Building Release for Team ID ${team}…"
    # NB: Signing settings come from Signing.xcconfig + Signing.local.xcconfig,
    # which are wired as baseConfigurationReference in the Xcode project.
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination 'platform=macOS' \
        -derivedDataPath "$DERIVED_DATA" \
        DEVELOPMENT_TEAM="$team" \
        build \
        | xcbeautify --quiet 2>/dev/null || true
    # The `|| true` + xcbeautify fallback keeps output usable even if xcbeautify
    # isn't installed. If the build actually failed, the next check catches it.

    local built="${DERIVED_DATA}/Build/Products/Release/${APP_NAME}"
    if [[ ! -d "$built" ]]; then
        err "Build did not produce ${built}."
        return 1
    fi
    echo "$built"
}

action_install() {
    require_xcodebuild
    local team
    team="$(require_signing_configured)" || return 1

    local built
    built="$(_build_release "$team")" || return 1

    local dest="/Applications/${APP_NAME}"
    if [[ -e "$dest" ]]; then
        info "Replacing existing ${dest}."
        rm -rf "$dest"
    fi

    info "Copying built app to ${dest}…"
    cp -R "$built" "$dest"

    # Clear the quarantine attribute so Gatekeeper doesn't prompt after install.
    xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true

    ok "Installed: ${dest}"
    printf "Launch now? [y/N] "
    local reply
    read -rsn1 reply
    echo
    [[ "$reply" =~ ^[Yy]$ ]] && open "$dest"
}

action_dmg() {
    require_xcodebuild
    local team
    team="$(require_signing_configured)" || return 1

    local built
    built="$(_build_release "$team")" || return 1

    local version
    version="$(read_marketing_version)"
    [[ -z "$version" ]] && version="dev"

    local staging="${BUILD_DIR}/dmg-staging"
    rm -rf "$staging" && mkdir -p "$staging"
    cp -R "$built" "$staging/"
    ln -s /Applications "$staging/Applications"

    mkdir -p "$DIST_DIR"
    local dmg="${DIST_DIR}/SynologyDSManager-${version}.dmg"
    rm -f "$dmg"

    info "Creating ${dmg}…"
    hdiutil create \
        -volname "SynologyDSManager ${version}" \
        -srcfolder "$staging" \
        -ov -format UDZO \
        "$dmg" >/dev/null

    # Sign the DMG itself so notarisation has something to verify.
    info "Code-signing DMG with Developer ID (Team ${team})…"
    codesign --force --timestamp --sign "Developer ID Application" "$dmg" \
        || warn "DMG signing failed. Check that 'Developer ID Application' is in your keychain."

    ok "DMG created: ${dmg}"

    # Optional notarisation. Looks for a notarytool keychain profile name in
    # `.notary-profile-name` (gitignored). If it's there and readable, offer
    # to notarise + staple.
    if [[ -f .notary-profile-name ]]; then
        local profile
        profile="$(tr -d '[:space:]' < .notary-profile-name)"
        if [[ -n "$profile" ]]; then
            printf "Notarise with profile '%s'? [y/N] " "$profile"
            local reply
            read -rsn1 reply
            echo
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                info "Submitting to Apple notary service (this can take a few minutes)…"
                if xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait; then
                    info "Stapling notarisation ticket to DMG…"
                    xcrun stapler staple "$dmg"
                    ok "Notarised and stapled."
                else
                    warn "Notarisation failed. Run 'xcrun notarytool log …' with the submission ID to inspect."
                fi
            fi
        fi
    else
        info "No .notary-profile-name file found — skipping notarisation."
        info "To enable, run 'xcrun notarytool store-credentials' and write the profile name to .notary-profile-name."
    fi
}

# ----- Menu ----------------------------------------------------------------

print_menu() {
    local team_id
    team_id="$(read_team_id)"
    local status_line
    if [[ -z "$team_id" || "$team_id" == "YOUR_TEAM_ID_HERE" ]]; then
        status_line="${YELLOW}signing not configured${RESET}"
    else
        status_line="${GREEN}signing: Team ${team_id}${RESET}"
    fi

    clear
    cat <<EOF
${BOLD}SynologyDSManager — deploy.sh${RESET}
${DIM}$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(no git branch)') · ${status_line}${DIM}${RESET}

  ${BOLD}p${RESET}   Pull main from origin to local
  ${BOLD}o${RESET}   Open in Xcode
  ${BOLD}s${RESET}   Configure signing (Apple Developer Team ID)
  ${BOLD}i${RESET}   Build Release and install to /Applications
  ${BOLD}d${RESET}   Build Release and create a DMG for distribution
  ${BOLD}q${RESET}   Quit

EOF
}

main_loop() {
    require_macos
    while true; do
        print_menu
        printf "Choose: "
        local key
        read -rsn1 key
        echo
        case "$key" in
            p|P) action_pull_main        || true; pause ;;
            o|O) action_open_xcode       || true; pause ;;
            s|S) action_configure_signing|| true; pause ;;
            i|I) action_install          || true; pause ;;
            d|D) action_dmg              || true; pause ;;
            q|Q) echo "Bye."; exit 0 ;;
            "")  ;;  # stray newline
            *)   warn "Unknown option: $key"; sleep 0.5 ;;
        esac
    done
}

main_loop "$@"
