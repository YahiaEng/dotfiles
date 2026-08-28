#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          ARCH LINUX HYPRLAND SETUP                   ║
# ║   Installs all dependencies for this rice            ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# Repo root, resolved from this script's own location so the system-file
# installs in section_hardware work regardless of the caller's cwd. Files
# under system/ target /etc and /usr/local, which are outside $HOME and
# therefore deliberately NOT stow-managed — stow.sh's PACKAGES array is an
# explicit list, so system/ is never stowed.
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ── Flag parsing ─────────────────────────────────────
# --core-only : run only section_core_rice (packages + AUR helper + core
#               post-install tasks). Skips section_hardware and
#               section_personal. Used by the container/VM verification
#               gate (D-52/D-57), where hardware guards and personal
#               config would be meaningless or destructive.
# --help/-h   : print usage and exit 0 before any sudo/pacman call.
# Any other flag is rejected loudly (Security V5) — never silently ignored.
CORE_ONLY=false
NVIDIA_INSTALLED=false

usage() {
    cat <<'USAGE'
Usage: install.sh [--core-only] [--help]

  --core-only   Install only the core rice section: pacman + AUR packages,
                AUR-helper bootstrap, audio/dbus-broker services, VSCodium
                extensions. Skips the hardware section (NVIDIA/limine) and
                the personal section (git identity, timezone). Intended
                for the container/VM verification gate.
  --help, -h    Show this help message and exit.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --core-only)
            CORE_ONLY=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "install.sh: unknown flag: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# ── Sudo keepalive (2026-08-27) ───────────────────────────────────────
# This script makes 47 sudo calls, and the AUR build sits between them —
# AUR_PKGS_HOST's own comment measures tela-icon-theme at 21min and
# colloid-icon-theme-git at 22min. sudo's default timestamp_timeout is 5
# minutes and this host sets no override, so the cached credential
# ALWAYS expires during that build and the next sudo re-prompts. The
# operator hit exactly this, mid-run, right after the hyprpm step:
#     [sudo] password for aorus:
# An install that stops for a password 40 minutes in, unattended, is a
# failed install.
#
# Prime once up front (so the password is asked for at the START, where
# someone is still watching), then refresh in the background until this
# script exits. `kill -0 $$` makes the refresher die with its parent
# rather than outliving it as a stray root-capable loop, and the trap
# closes the window where the script exits between refreshes.
sudo -v
while true; do
    sudo -n true 2>/dev/null || exit
    sleep 50
    kill -0 "$$" 2>/dev/null || exit
done &
SUDO_KEEPALIVE_PID=$!
# shellcheck disable=SC2064  # expand SUDO_KEEPALIVE_PID now, not at trap time
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null || true" EXIT

# makepkg OPTIONS with `debug` turned off, derived from the SYSTEM config
# rather than hardcoded — if Arch changes its defaults, this follows them
# and only flips the one option we care about. See the AUR install call in
# section_core_rice for why.
MAKEPKG_OPTIONS_NODEBUG="$(
    { grep -E '^OPTIONS=' /etc/makepkg.conf 2>/dev/null || echo 'OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge lto)'; } \
    | head -1 | sed -E 's/^OPTIONS=\(//; s/\)$//' \
    | sed -E 's/(^| )!?debug( |$)/\1!debug\2/'
)"

# ── Official repo packages (core — always installed) ─
PACMAN_PKGS=(
    # Hyprland ecosystem
    hyprland
    hypridle
    # The external lock binary was REMOVED 2026-08-27 (quick task
    # 260827-ar3), replaced by the in-process Quickshell lock screen
    # (260827-833). Its config, matugen template, contract entry and
    # screencopy grant went with it. Deliberately not named here: the
    # install-stow-lists retirement class greps this file WITHOUT
    # skipping comments, so writing the name back would re-fail the gate
    # this removal exists to turn green.
    # hyprshutdown REMOVED 2026-08-27 (quick task 260827-74s) — zero consumers.
    # It wrapped Log Out, Reboot and Shut Down in PowerActions.qml; all three
    # dropped it because it waits on apps with no timeout of any kind and only
    # its own "Force quit" button ends the wait. Reinstall by hand if you ever
    # want its `--vt N` NVIDIA+SDDM black-screen workaround.
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

    # Session manager
    uwsm
    dbus-broker

    # Terminal
    kitty

    # Shell (interactive, launched via kitty.conf; login shell stays zsh — D-12)
    fish

    # Searchable shell history for fish (Ctrl-R / Up). Official `extra`
    # repo, pacman — verified with `pacman -Si atuin` (18.19.0-1) before
    # this line was added, NOT the AUR. config.fish sources it behind a
    # `command -q atuin` guard, so a machine that has not reached this
    # step yet still opens a clean shell. Local-only by default: `atuin
    # init` starts no sync and needs no account.
    atuin

    # Themed terminal multiplexer (D-01/D-06, quick task 260820-0ha):
    # official `extra` repo, pacman — NOT the AUR, verified installed at
    # 0.44.3-1 on this host, with only curl/glibc/libgcc/zlib as
    # dependencies. zellij requires no plugin manager, no git clone and no
    # headless fetch step at all — session_serialization/
    # serialize_pane_viewport are built-in options, so stow.sh needs no
    # fetch step for it at all.
    zellij

    # Themed neovim (quick task 260820-nua): official `extra` repo, pacman
    # — NOT the AUR, both measured present via `pacman -Si` before this
    # line was added. `git`, `ripgrep`, `fd`, `gcc` (via base-devel),
    # `curl` and `unzip` are already covered by existing entries or the
    # paru bootstrap above — nothing else is needed for lazy.nvim itself.
    #
    # neovim 0.12.4-1 — the editor.
    neovim
    # tree-sitter-cli 0.26.9-1 — required by nvim-treesitter's `main`
    # branch to compile a parser from source at first launch. Confirmed
    # NOT installed on this host by default; without it, parser
    # installation fails SILENTLY (the plugin logs a warning per parser,
    # but nvim itself starts clean) and every buffer opens with no syntax
    # highlighting at all, with nothing in the way that points at a
    # missing compiler as the cause.
    tree-sitter-cli
    # lua-language-server 3.19.1-1 — Rule 2 addition (missing critical
    # functionality), not in the original plan for this task. The LSP
    # config in lua/plugins/lsp.lua enables `lua_ls`, but its binary was
    # not installed on this host and nothing in this file provided it —
    # without this line, LSP silently never attaches to a Lua buffer on a
    # fresh install, which is most of what this config's own source tree
    # is written in. Confirmed via `pacman -Si` before adding, same as the
    # two entries above.
    lua-language-server
    # Deliberately NOT here: a headless plugin restore. install.sh runs
    # BEFORE stow.sh (this script's own next-steps message says so), so
    # ~/.config/nvim does not exist yet at this point — the restore lives
    # in stow.sh, right after its first-boot theme seed, where both the
    # config tree and the rendered palette already exist.

    # Wallpaper
    awww

    # Utilities
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    fastfetch
    fzf
    chafa
    imagemagick
    # python-pillow: fastfetch-sprites.py's Pillow dependency (quick task
    # 260818-srl). Official `extra`-repo pacman package, confirmed via
    # `pacman -Si python-pillow` before this line was added — not AUR, no
    # build recipe (T-srl-04). Without it a fresh install silently gets
    # ASCII-only fastfetch logos forever, with no diagnostic (the fish
    # selector degrades gracefully to themed ASCII when a sprite GIF is
    # missing, per its own T-srl-01 validation — but the sprite feature
    # itself would never work).
    python-pillow
    jq
    psmisc
    rsync
    stow
    # Phase 18/RETIRE-02 review WR-02: explicit, not transitive. The
    # theme-engine's lib/wallpaper.sh invokes `ffmpeg` directly to extract
    # the still frame a live wallpaper hands to the lock screen, and
    # scripts/gif-export.sh runs a two-pass palettegen/paletteuse
    # conversion through it. `ffmpegthumbnailer` is listed further down for
    # Thunar/yazi thumbnails and does NOT provide /usr/bin/ffmpeg — the two
    # are different packages solving different problems. ffmpeg was already
    # present transitively on the development host, which is exactly the
    # host-only-state failure class ROADMAP standing constraint 3 forbids.
    ffmpeg
    # Phase 18/RETIRE-02 review WR-01: provides `checkupdates`, which the
    # QML bar's SystemCapsule.qml invokes directly on an always-on
    # 30-minute poll (updatesCheckCommand). Without it the bar's updates
    # readout is permanently dead on a fresh install with no error a user
    # would connect to a missing package. Same host-only-state class as
    # the `lua` and `adw-gtk-theme` entries above.
    pacman-contrib
    # Phase 13.1/D-14: explicit dependency, not a transitive one — the
    # theme-engine's lib/contract.sh lua-table extractor invokes `lua`
    # directly (dofile()+walk) to parity-check hyprland-tokens.lua. `lua`
    # was already present transitively via hyprland's own Depends On, but
    # ROADMAP standing constraint 3 requires a runtime dependency this
    # repo's own tooling calls be declared explicitly, not inherited.
    lua

    # Audio
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
    # Network management (D-15-23): official extra repo, not AUR. Provides
    # the wifi panel's Advanced target — PANEL-05's third manager, alongside
    # pavucontrol/blueman. Was host-only state (unlisted but already
    # installed) — same failure class as the missing adw-gtk-theme package.
    #
    # 15-13 (G-15-4): the package is DELIBERATELY RETAINED for
    # nm-connection-editor, while its autostarted secret agent (nm-applet)
    # is suppressed by the stowed XDG override at
    # quickshell/.config/autostart/nm-applet.desktop. That agent owned the
    # external GTK passphrase dialog that rendered behind the wifi panel;
    # the wifi panel now supplies passphrases natively. Do NOT remove this
    # package because that override exists — they are two halves of one
    # decision, and each names the other so either end is discoverable.
    network-manager-applet

    # Fonts
    otf-firamono-nerd
    ttf-firacode-nerd
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    otf-font-awesome

    # File manager
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler
    gvfs
    gvfs-mtp
    yazi
    ffmpegthumbnailer
    fd
    resvg
    ripgrep
    poppler
    zoxide
    7zip

    # Polkit
    polkit-gnome

    # Qt Wayland
    qt5-wayland
    qt6-wayland

    # Qt image format plugins — REQUIRED for .webp wallpapers to render in
    # the Quickshell shell. Without it qt6-base ships only gif/ico/jpeg/svg
    # and a .webp still cannot draw at all, while a .webp live wallpaper
    # shows its extracted poster frame for ever.
    #
    # Do NOT trust this package's description to decide whether it belongs
    # here: it advertises only "TIFF, MNG, TGA, WBMP" and omits three of the
    # seven plugins it actually ships. Verified 2026-08-26 by listing the
    # real package contents (6.11.2-1) rather than reading the blurb —
    # usr/lib/qt6/plugins/imageformats/ contains libqicns, libqjp2, libqmng,
    # libqtga, libqtiff, libqwbmp AND libqwebp. `Depends On: libwebp`
    # corroborates. The stale description is why this was left out for so
    # long, filed as an unconfirmed candidate.
    qt6-imageformats

    # QtMultimedia — REQUIRED for VIDEO live wallpapers (mp4/mkv/webm/mov).
    # WallpaperTile.qml imports QtMultimedia and drives MediaPlayer +
    # VideoOutput; without these the import fails and every video wallpaper
    # is dead, the same silent shape the missing webp plugin had.
    #
    # Found 2026-08-26 by the same audit that confirmed qt6-imageformats,
    # and it hid for the same reason: neither package ships a BINARY, so
    # nothing that enumerates invoked commands can ever see them. On this
    # host qt6-multimedia was present only because ktextwidgets/qt6-speech
    # happened to pull it — `pactree -r` shows NO declared package requires
    # it. A fresh install would have had none of it. (qt6-declarative, by
    # contrast, IS genuinely covered: quickshell depends on it, exactly as
    # the quickshell entry below claims.)
    #
    # The backend is named explicitly on purpose. qt6-multimedia depends on
    # the VIRTUAL `qt6-multimedia-backend`, which has two providers here
    # (qt6-multimedia-ffmpeg and qt6-multimedia-gstreamer), and this script
    # installs with --noconfirm — so leaving the choice implicit means an
    # ambiguous provider resolution rather than a deliberate one. ffmpeg is
    # the provider proven working on this host and is already a dependency
    # of the wallpaper pipeline's own poster-frame extraction.
    qt6-multimedia
    qt6-multimedia-ffmpeg

    # Quickshell (QS-01: official extra repo, not AUR — the only new line;
    # pacman's own resolver pulls the whole Qt6 declarative/SVG stack and
    # its stack-trace runtime dependency automatically, verified against
    # 11-QUICKSHELL-EVIDENCE.md's captured `pacman -Si` Depends On closure)
    quickshell

    # Misc
    libnotify
    python-gobject
    gtk3
    adw-gtk-theme

    # Screenshots, screen recording, OSD, utilities (D-03/D-16/D-18/D-23 —
    # all 13 confirmed official `extra` repo per RESEARCH Package
    # Legitimacy Audit, none are AUR)
    hyprshot
    satty
    gpu-screen-recorder
    hyprpicker
    wtype
    ddcutil
    papirus-icon-theme
    ttf-jetbrains-mono-nerd
    ttf-cascadia-code-nerd
    ttf-hack-nerd
    ttf-iosevka-nerd
    ttf-meslo-nerd
    # vlc + vlc-plugins-all (SHOT-03): Arch's vlc 3.0.23_2 packaging split codec
    # plugins out of the base `vlc` package into `vlc-plugins-*`, so a fresh
    # install of `vlc` alone cannot decode gpu-screen-recorder output.
    vlc
    vlc-plugins-all
    # xdg-user-dirs: provides `xdg-user-dir` and creates ~/Pictures so
    # screenshot-dir resolution is deterministic on a fresh install.
    xdg-user-dirs

    # Personal
    zip
    unzip
    libreoffice-fresh
    obsidian

    # DevOps
    ansible
    aws-cli-v2
    kubectl
    github-cli
    vault
    terraform

    # ── Game center + AI dashboard (D-25/D-33 — 8 confirmed official
    # extra/multilib repo per RESEARCH Package Legitimacy Audit, none
    # are AUR). aichat chosen over AUR-only oterm for D-22 (official
    # repo, Rust, multi-provider, speaks Ollama's OpenAI-compatible
    # endpoint at localhost:11434/v1). blueman chosen over AUR-only
    # overskride for D-18 (official repo; windowrules.conf already
    # carries a float-blueman rule for the blueman-manager class).
    steam       # multilib — see the multilib enablement step above
    lutris
    ollama
    aichat
    gamemode
    mangohud
    nwg-displays
    blueman

    # Audio analyser + sass compiler (official extra repo). cava is the
    # underlay the QML Media tab's live 60-bar visualiser ring feeds from
    # (RETIRE-06, Phase 21 — CavaService.qml, MediaTab.qml, DashboardTab.qml,
    # Design.qml). dart-sass provides the `sass` binary — NOT for the
    # retired GTK4 media applet that used to own this comment: stow.sh's
    # GTK3 seed block (D-01/D-05/13-02/13-05) shells out to it independently
    # to compile the GTK3 sass partial at install time, with zero relation
    # to that retired package. Removing this package on the strength of the
    # old attribution would leave GTK3 surfaces unstyled on a fresh install.
    cava
    dart-sass

    # ── hyprpm build toolchain (AMB-02/D-33 — Phase 17 plan 04) ──
    # hyprpm is the optional build/load manager for the dynamic-cursors
    # plugin below. Its own binary states its full requirement list
    # verbatim: `strings /usr/bin/hyprpm | grep -i "Hyprpm requires"` ->
    # "Hyprpm requires: cmake, cpio, pkg-config, git, g++, gcc"
    # (17-RESEARCH.md Deep-Dive #4, verified against the installed
    # hyprland 0.56.2-1 package this session). `pkg-config` is provided by
    # `pkgconf`, `git` and `gcc`/`g++` are already present (gcc provides
    # both), all conditionally-but-reliably declared elsewhere in this
    # script — cmake and cpio were the two genuinely undeclared gaps,
    # confirmed absent from the full PACMAN_PKGS array before this edit.
    # cpio in particular was present on the reference host only
    # transitively (via debugedit/dracut/virt-install) — exactly the
    # host-only-state class the reproducibility constraint forbids, so it
    # must be declared explicitly rather than relied upon.
    cmake
    cpio

    # ── Security Center scanners (quick task 260827-np1) ──
    # The operator's brief was explicit: "whichever is more secure, this
    # is my priority" — so the full set installs by default rather than
    # being offered from the pane. All four are in official `extra`; none
    # needs an AUR helper, which is why they sit here and not in
    # AUR_PKGS.
    #
    # These land in VERIFY_PKGS with everything else, so a fresh install
    # that silently fails to fetch one of them HARD-FAILS rather than
    # producing a Security Center whose scanners are all "not installed"
    # — the exact adw-gtk3 ghost class verify_packages exists to catch.
    #
    # clamav is the expensive one (30.7 MiB plus a ~300 MB signature
    # database). Its freshclam service is enabled in section_security
    # below, NOT here: a clamav with no signatures scans nothing and
    # reports clean, which is the single worst failure this pane could
    # have — a false all-clear.
    clamav
    arch-audit
    rkhunter
    lynis
    # smartmontools provides smartctl AND smartd; the Security Center's
    # device-health half is unreadable without it. Declared explicitly
    # rather than relied on transitively (it was already present on the
    # reference host, which is exactly the host-only-state class the
    # reproducibility constraint forbids).
    smartmontools
)

# ── Official repo packages (hardware — NVIDIA GPU only) ─
# nvidia-open-dkms, NOT nvidia-dkms: Arch dropped the proprietary kernel
# modules at driver 610 — `nvidia`, `nvidia-dkms` and `nvidia-lts` are gone
# from the repos. nvidia-open-dkms declares Provides/Replaces on nvidia-dkms
# so the old name still resolved, but it no longer says what it means.
# Only the KERNEL modules are open; nvidia-utils (the userspace driver —
# OpenGL/Vulkan/CUDA/NVENC) is the same proprietary blob either way. The open
# modules require Turing or newer, since they offload hardware management to
# the GPU's GSP coprocessor.
NVIDIA_PKGS=(
    nvidia-open-dkms
    nvidia-utils
    libva-nvidia-driver
    egl-wayland
)

# ── Fallback kernel (hardware — boot resilience) ────────
# A second bootable kernel, so a driver/kernel mismatch on the mainline kernel
# is an inconvenience rather than an unusable system. On 2026-07-28 the
# mainline kernel updated without its NVIDIA modules getting built and the
# only recovery path was appending "3" at the bootloader to reach a console.
#
# linux-lts-headers is required because the driver is DKMS and must compile
# against this kernel too. (It would be unnecessary under a prebuilt
# nvidia-open-lts strategy — deliberately not what this repo uses; DKMS covers
# every installed kernel from one package and is guarded by
# kernel-module-verify.)
FALLBACK_KERNEL_PKGS=(
    linux-lts
    linux-lts-headers
)

# ── AUR packages (core — always installed) ───────────
AUR_PKGS=(
    # Rice
    matugen-bin

    # Z-shell
    zsh
    oh-my-posh

    # Code editors
    vscodium-bin

    # Browsers
    zen-browser-bin

    # Other
    spotify
    discord
    1password
    # octopi-git, NOT octopi (fixed 2026-08-27, quick task 260827-np1).
    # `octopi` depends on `alpm_octopi_utils`, which CONFLICTS with the
    # `alpm_octopi_utils-git` this host already has installed. pacman
    # cannot resolve a conflict under --noconfirm, so the whole
    # section_core_rice transaction aborts with:
    #     :: Conflicts found:
    #         octopi: alpm_octopi_utils-git (alpm_octopi_utils)
    #     error: can not install conflicting packages with --noconfirm
    # That halted install.sh before section_security ever ran.
    # `octopi-git` is the same program and depends on the -git utils
    # package that is already present, so it resolves cleanly.
    octopi-git

    # Icon themes (D-16 — human package-legitimacy checkpoint approved).
    # tela-icon-theme and colloid-icon-theme-git moved to AUR_PKGS_HOST
    # below (22-09 perf).
    #
    # papirus-folders was REMOVED here and is deliberately not a dependency
    # any more. It rewrites folder symlinks inside /usr/share/icons, so it
    # re-execs itself under sudo unless the theme lives in $HOME — meaning
    # either a root call on every theme switch or a 19MB copy of
    # Papirus-Dark in $HOME that goes stale on package update. Both are
    # host-only state this repo forbids. theme_engine_papirus_folder_overlay
    # in lib/gtk.sh now does the same job with a user-level shadow theme
    # made of symlinks into the system icons — no root, no package, nothing
    # to refresh. papirus-icon-theme (pacman, above) is still required.

    # Game center (D-33 — human package-legitimacy checkpoint approved
    # 2026-07-13). protonup-qt is AUR-only — this corrects CONTEXT.md
    # D-25's assumption that it was an official-repo package; do not
    # "fix" it back into PACMAN_PKGS, it does not exist there.
    heroic-games-launcher-bin
    protonup-qt

    # Material Symbols Rounded icon font (D-28 — human package-legitimacy
    # checkpoint approved 2026-07-29, evidence in 14-02-SUMMARY.md: package
    # base material-symbols-git, maintainer moetayuko/xiota, 7 votes/1.34
    # popularity, not out-of-date, PKGBUILD source= pulls TTFs directly from
    # Google's own github.com/google/material-design-icons, package()
    # installs only .ttf files under /usr/share/fonts). This is an unpinned
    # -git package verified by presence only, not by version — the same
    # property colloid-icon-theme-git already has in AUR_PKGS_HOST below.
    ttf-material-symbols-variable-git

    # Live wallpaper player (D-23 — package-legitimacy audit in
    # 17-RESEARCH.md §"Package Legitimacy Audit": verdict OK, AUR since
    # 2020-09-10, last modified 2026-07-19, 19 votes/0.44 popularity,
    # upstream github.com/GhostNaN/mpvpaper at 1561 stars, pushed
    # 2026-07-25, not archived. Hard dependency — an animated/video
    # wallpaper in ~/Pictures/Wallpapers/<theme>/live/ has nothing to play
    # it without this binary; libmpv arrives transitively.
    mpvpaper

    # Cursor theme, hyprcursor half (D-32, package half — Phase 17 plan
    # 04). Hard dependency: verify_packages() covers it automatically via
    # the VERIFY_PKGS union below, same as every other AUR entry in this
    # array. Legitimacy audit (17-RESEARCH.md §"Package Legitimacy
    # Audit"): verdict OK, AUR first submitted 2024-03-14, last modified
    # 2024-03-24, 7 votes, upstream github.com/ndom91/rose-pine-hyprcursor,
    # already installed and verified on the reference host at
    # v0.3.2.r0.d2c0e680-1. Consumed by env.lua's HYPRCURSOR_THEME
    # (plan 05, option-c) — the pin and this entry must be removed
    # together or not at all, out of the criterion-3 cut sweep's scope
    # (17-06, D-38).
    rose-pine-hyprcursor

    # Cursor theme, XCursor half (D-32, option-c — Phase 17 plan 05, human
    # package-legitimacy checkpoint approved). Provides the XCursor-format
    # sibling of rose-pine-hyprcursor directly above — both are the same
    # BreezeX-remixed-to-Rose-Pine shape family (rose-pine-hyprcursor's
    # own manifest.hl description names this), so native Wayland clients
    # (via HYPRCURSOR_THEME) and XWayland/GTK clients (via XCURSOR_THEME
    # and gtk-cursor-theme-name) render matching shapes and colors instead
    # of two unrelated themes. Legitimacy audit (live, this session): AUR
    # first submitted 2024-01-11, last modified 2024-01-12, 9 votes/1.38
    # popularity, maintainer That1Calculator, not out-of-date; upstream
    # github.com/rose-pine/cursors (renamed from .../cursor — GitHub's own
    # repo-rename redirect, confirmed via the numeric repo ID, not a
    # hijack), 184 stars, pushed 2026-06-24, not archived. PKGBUILD read
    # line by line: downloads two pinned-sha256 upstream release assets
    # and copies them verbatim into /usr/share/icons — no build step. The
    # pinned sha256 was independently re-derived from the real upstream
    # asset and matched exactly. Installed directory names are
    # BreezeX-RosePine-Linux and BreezeX-RosePineDawn-Linux — NOT the
    # package name; verified present on disk before this entry landed.
    # Only the -Linux (dark) variant is consumed anywhere in this repo —
    # the -Dawn (light) variant is NOT wired to theme mode (see
    # generate.sh's own D-07 note: cursor is a mode-orthogonal axis
    # already, matching font/icon-theme's existing pattern; wiring a
    # light-mode cursor swap is a new capability this plan does not add).
    # Replaces bibata-cursor-theme (D-32 supersedes it; nothing in this
    # repo names Bibata-Modern-Classic any more after plan 05 — removed
    # from AUR_PKGS in the same commit as this addition, not left as dead
    # weight).
    rose-pine-cursor
)

# ── AUR packages (host-only — skipped under --core-only) ─
# Bootloader + kernel hooks: host-only. A container has no bootloader and
# never reaches a boot, so these are out of --core-only scope for the same
# reason install.sh:816's kernel-module-verify check skips there ("no
# hardware section ran, so there is no kernel/driver work to check"). A
# default (no-flag) run still appends and installs both — this changes only
# the container-gate scope, not the real host install.
AUR_PKGS_HOST=(
    # Limine Bootloader
    limine-dracut-support
    kernel-modules-hook

    # Icon themes, heavy-build half (22-09 perf — measured, not a guess):
    # tela-icon-theme took 21min and colloid-icon-theme-git took 22min in
    # the 22-BASELINE.md run (03-install.log timestamp diffs), 43 of the
    # baseline's ~62-minute total. The cost is package() copying tens of
    # thousands of small icon files onto overlayfs, not compression. Safe
    # to skip under --core-only: icon-theme-picker.sh discovers installed
    # themes at runtime and explicitly handles the case where only
    # Adwaita is present (icon-theme-picker.sh:124-126, MAINT-03's
    # Ctrl-A browse-and-install path), and no .ini/.lua/.toml/.conf/.qml
    # file in this repo references either theme by name — nothing in the
    # theme pipeline hardcodes them. colloid-icon-theme-git note: the
    # plain colloid-icon-theme name does NOT exist on AUR, only the -git
    # suffix does. A default (no-flag) run still installs both — this
    # changes only the container-gate scope, not the real host install.
    tela-icon-theme
    colloid-icon-theme-git
)

if [[ "$CORE_ONLY" != "true" ]]; then
    AUR_PKGS+=("${AUR_PKGS_HOST[@]}")
fi

# ── section_core_rice ─────────────────────────────────
# Mirror sync, AUR-helper bootstrap, pacman + AUR package installs,
# orphan cleanup, audio/dbus-broker services, VSCodium extensions.
# Always runs — this is the section the container/VM gate exercises
# via --core-only, and what a default (no-flag) run always includes.
section_core_rice() {
    echo "╔══════════════════════════════════════════╗"
    echo "║   Installing Hyprland Rice Dependencies  ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    echo "Synchronizing closest mirrors..."
    echo ""
    # D-59 (strictly zero prompts): every pacman/paru invocation in this
    # script must carry --noconfirm — the container gate's first real run
    # (verify/logs/run-20260708T220706Z) caught `pacman -Syu` prompting
    # ":: Proceed with installation? [Y/n]" on an archlinux-keyring upgrade.
    sudo pacman -Sy --needed --noconfirm reflector
    sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    sudo reflector --verbose --latest 30 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    sudo pacman -Syu --noconfirm

    # ── Check for yay/paru ───────────────────────────────
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    else
        echo "⚠  No AUR helper found. Installing paru..."
        sudo pacman -Sy --needed --noconfirm git base-devel rustup
        rustup default stable
        # WR-09: a stale clone from a prior interrupted/re-run leaves
        # /tmp/paru non-empty, which makes `git clone` fail — clear it first
        # so the bootstrap is idempotent on a re-run.
        rm -rf /tmp/paru
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru && makepkg -si --noconfirm
        AUR_HELPER="paru"
    fi

    echo ""
    echo "Using AUR helper: $AUR_HELPER"
    echo ""

    # ── Enable multilib repo (D-25, RESEARCH.md Pitfall 2) ───────────
    # Steam (below, PACMAN_PKGS) lives in the [multilib] repo, which Arch
    # ships commented-out by default. This repo had ZERO pre-existing
    # pacman.conf-editing code before this block (`grep -n
    # "multilib\|pacman.conf" install.sh` returned no matches). This dev
    # machine ALREADY has [multilib] enabled by hand, which is exactly
    # what silently masked this gap during local testing — a genuinely
    # fresh system would fail at the `steam` install line without this
    # step. Idempotent by design (safe to re-run against an already-
    # enabled pacman.conf). Do NOT delete this as "redundant" just
    # because it happens to be a no-op on this particular machine.
    echo "Ensuring [multilib] repo is enabled..."
    if grep -q '^\[multilib\]' /etc/pacman.conf; then
        echo "  [multilib] already enabled — skipping."
    elif grep -q '^#\[multilib\]' /etc/pacman.conf; then
        # Uncomment BOTH the header and its immediately-following Include
        # line together, anchored specifically to the multilib stanza (N
        # joins the two lines into one pattern space before substituting)
        # — never a blanket #Include uncomment, which would also enable
        # any other commented repo (e.g. [testing]/[multilib-testing]).
        sudo sed -i \
            '/^#\[multilib\]$/{N;s/^#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist$/[multilib]\nInclude = \/etc\/pacman.d\/mirrorlist/}' \
            /etc/pacman.conf
        echo "  Uncommented [multilib] in /etc/pacman.conf."
    else
        # Neither an active nor a commented [multilib] section exists at
        # all — append the standard two-line stanza.
        printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
        echo "  Appended [multilib] to /etc/pacman.conf."
    fi
    # Sync the newly (or already) enabled repo's database before any
    # package that lives there (steam) is installed — without this,
    # `pacman -S steam` still fails with "target not found" even though
    # the repo section itself is now active.
    sudo pacman -Sy --noconfirm
    echo ""

    echo "Installing pacman packages..."
    sudo pacman -Sy --needed --noconfirm "${PACMAN_PKGS[@]}"

    echo ""
    echo "Installing AUR packages..."
    # ── Disable makepkg's `debug` option for these builds (2026-08-27) ──
    # Arch ships `debug` in /etc/makepkg.conf's OPTIONS by default, which
    # makes makepkg copy every SOURCE FILE into /usr/src/debug/ after
    # package(). For a compiled package that is useful. For an icon theme
    # it is pure waste: tela-icon-theme has no binaries and therefore no
    # debug symbols at all, yet the copy still grinds through its whole
    # tree — MEASURED on this host at a 1.3 GB build directory, and the
    # operator reported install.sh appearing to hang at exactly that step
    # ("Copying source files needed for debug symbols...").
    #
    # AUR_PKGS_HOST's own comment already measures tela-icon-theme at
    # 21min and colloid-icon-theme-git at 22min — 43 of a ~62-minute
    # install. This removes the debug half of that cost.
    #
    # Scoped to THIS invocation via a generated config, deliberately NOT
    # written to ~/.makepkg.conf: that file would silently change every
    # future AUR build the operator ever runs, which is well outside what
    # a dotfiles installer should own. makepkg reads --config as a full
    # replacement, so it is sourced from the system file and only OPTIONS
    # is overridden.
    local MAKEPKG_CONF
    MAKEPKG_CONF="$(mktemp -t makepkg-nodebug.XXXXXX.conf)"
    {
        cat /etc/makepkg.conf
        echo ""
        echo "# Appended by install.sh — see the comment at this call site."
        echo "OPTIONS=(${MAKEPKG_OPTIONS_NODEBUG})"
    } > "$MAKEPKG_CONF"
    $AUR_HELPER -Sy --needed --noconfirm --mflags "--config $MAKEPKG_CONF" "${AUR_PKGS[@]}"
    rm -f "$MAKEPKG_CONF"

    echo ""
    echo "Removing unused packages and clearing cache..."
    # Pitfall 4: a fresh install has zero orphans, so the old unquoted
    # command substitution passed directly to $AUR_HELPER -R ran it against
    # an empty string and aborted the script under set -e. Array-collect +
    # count-guard: zero orphans is a no-op, multiple orphans expand
    # correctly, and the removal never prompts (--noconfirm).
    mapfile -t ORPHANS < <(pacman -Qtdq || true)
    if (( ${#ORPHANS[@]} > 0 )); then
        "$AUR_HELPER" -R --noconfirm "${ORPHANS[@]}"
    fi
    # $AUR_HELPER -Sc prompts "remove all other packages from cache? [Y/n]"
    # without --noconfirm — same D-59 zero-prompt violation class as the -Syu above.
    "$AUR_HELPER" -Sc --noconfirm

    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     All packages installed successfully! ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     Post installation tasks              ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    # ── Install vscodium theme extensions ────────────────
    echo ""
    echo "Installing VSCodium theme extensions..."
    chmod +x "$HOME"/.config/hypr/scripts/vscodium-extensions.sh || true
    "$HOME"/.config/hypr/scripts/vscodium-extensions.sh 2>/dev/null || true

    # ── Make sure audio services are enabled ────────────────
    echo ""
    echo "Enabling audio services..."
    systemctl --user enable --now pipewire.service wireplumber.service pipewire-pulse.service

    # ── Enable dbus-broker (recommended for uwsm) ───────
    echo "Enabling dbus-broker for uwsm..."
    systemctl --user enable --now dbus-broker.service 2>/dev/null || true

    # ── Enable ollama (D-23) ─────────────────────────────
    # Install + enable only — NO model pull here. A multi-GB model
    # download would wreck the unattended container gate and fresh-install
    # time (D-23/D-34); model acquisition is a manual user step, surfaced
    # by the UI-SPEC's "No Model Installed" notification (plan 07-06).
    # Default bind is 127.0.0.1:11434 (loopback-only) — this script
    # deliberately never overrides the daemon's listen-address env var;
    # exposing it to 0.0.0.0 would open an unauthenticated inference API
    # to the LAN (T-07-09). Non-fatal/non-silenced (warn on stderr, never
    # `|| true`), so the container gate (systemd not PID 1) stays green
    # without hiding a real failure on bare metal.
    echo "Enabling ollama..."
    sudo systemctl enable --now ollama.service || echo "  ⚠ ollama enable failed" >&2
    echo ""

    # ── D-33: optional dynamic-cursors hyprpm block (AMB-02) — BEGIN ──
    # Phase 17 plan 04. hyprpm is the build/load manager for the optional
    # `dynamic-cursors` plugin (D-32/D-35). This block is intentionally
    # copied from the ollama warn-and-continue guard shape directly above
    # (command-then-warn-on-stderr), NOT from
    # verify_packages() below — that function's own comment states "No
    # warn-and-continue path" and exists specifically to hard-fail on a
    # missing REQUIRED package. Nothing in this block may ever be added
    # to VERIFY_PKGS: doing so would convert an optional dependency into
    # an install-abort and destroy AMB-02's criterion 2.
    #
    # Living inside section_core_rice is deliberate, not incidental: this
    # is the exact section the `--core-only` container gate always runs,
    # and a container has no compositor — so every failure path below is
    # exercised on every gate run, not just once on a fresh desktop
    # install. If hyprpm ever silently starts succeeding unattended here,
    # that would be the surprise, not the routine warning.
    #
    # What this block does NOT do: it never widens sudo scope (no policy
    # file, no NOPASSWD rule), and it never prompts — a hang is a worse
    # failure than the abort criterion 2 already forbids (T-17-06,
    # T-17-08). If credentials are unavailable it skips cleanly; the
    # post-login completion helper (hyprpm-complete.sh) finishes the job
    # once a real session exists (D-33's two-part design).
    #
    # HYPRPM_PLUGIN_URL is overridable from the environment SOLELY so
    # D-34's fault injection (Phase 17 plan 04, Task 3) can exercise this
    # literal shipped code path against a repository that cannot resolve,
    # rather than a hand-copied paraphrase. The audited upstream URL
    # below is the only value ever committed to this file (T-17-07).
    HYPRPM_PLUGIN_URL="${HYPRPM_PLUGIN_URL:-https://github.com/virtcode/hypr-dynamic-cursors}"

    # Non-interactive sudo credential check (RESEARCH.md A3, strengthened):
    # hyprpm shells out to sudo internally for its root-owned state store
    # at /var/cache/hyprpm/. A bare interactive `sudo -v` would still
    # prompt for a password if the cached timestamp has expired — and a
    # prompt in an unattended run is a hang, strictly worse than the
    # abort criterion 2 forbids. `sudo -n -v` inside `if !` cannot trip
    # `set -e`, and on failure this skips the plugin build entirely
    # rather than risk blocking login.
    if ! sudo -n -v 2>/dev/null; then
        echo "  ⚠ dynamic-cursors: no cached sudo credentials — skipping optional plugin build (hypr/.config/hypr/scripts/hyprpm-complete.sh completes it after login)" >&2
    else
        echo "Registering hypr-dynamic-cursors plugin (optional)..."
        # Guard registration behind a check for an already-registered
        # repository so a re-run of install.sh (expected to be
        # re-runnable) never emits a spurious warning here.
        if ! hyprpm list 2>/dev/null | grep -q 'dynamic-cursors'; then
            timeout 30 hyprpm add "$HYPRPM_PLUGIN_URL" || echo "  ⚠ hyprpm add dynamic-cursors failed" >&2
        fi
        # [Rule 1 fix, found live in Task 3's fault injection] every hyprpm
        # call below is timeout-bounded: if a live Hyprland session is
        # already running (a re-run of install.sh against an existing
        # desktop, not just a fresh headless install) and
        # ecosystem.enforce_permissions is on with no `plugin`-type grant
        # for hyprpm, hyprpm's own load step pops a real GUI Allow/Deny
        # dialog and BLOCKS until a human clicks it — live-reproduced this
        # session, a bare `hyprpm reload` hung past 120s with no default
        # action. A timeout bound is what keeps this block's own "never
        # blocks" promise true even when that dialog has no one to answer
        # it; the systemic fix (a `plugin` grant for hyprpm) lives in
        # hypr/.config/hypr/config/permissions.lua and requires a Hyprland
        # restart to take effect, per that file's own documented rule.
        timeout 15 hyprpm enable dynamic-cursors || echo "  ⚠ hyprpm enable dynamic-cursors failed" >&2
        timeout 180 hyprpm update || echo "  ⚠ hyprpm update (dynamic-cursors) failed — see above" >&2
    fi
    # ── D-33: optional dynamic-cursors hyprpm block (AMB-02) — END ──

    # ── zellij plugins (quick task 260820-1kp) ──────────────────────────
    # Two .wasm plugins, fetched from pinned GitHub release assets.
    #
    # It was four. monocle and room were dropped on 2026-08-20 after
    # monocle panicked on the live desktop at src/main.rs:16 — 223 times
    # in two minutes — having been released seventeen months before this
    # zellij. Their jobs are now done by `filepicker` and
    # `session-manager`, which ship INSIDE the zellij binary and so are
    # version-matched by construction. Only plugins with no in-tree
    # equivalent are fetched here: zjstatus (theming) and autolock.
    #
    # Why a fetch step at all, when the zellij package block above states
    # zellij needs none: that comment was true and stays true for zellij
    # ITSELF (session_serialization and the built-in bar are options, not
    # plugins). These four are third-party additions, and NONE of them is
    # packaged in the AUR or the official repos — measured, not assumed.
    # A fetch is therefore the only available mechanism.
    #
    # This is strictly MORE reproducible than the plugin-manager approach
    # the previously retired multiplexer used, which cloned plugin repos at
    # whatever HEAD happened to be current (that surface's name is left out
    # deliberately — retirement-check scans this file as a blocking class).
    # Every asset below is pinned to an exact
    # release tag AND verified against a sha256 recorded at the time it
    # was measured, so a silently re-tagged or tampered asset fails the
    # install instead of landing unnoticed.
    #
    # Never fatal: a plugin that fails to fetch or fails its checksum is
    # skipped with a warning. zellij starts fine without them — the bar
    # falls back to the built-in one and the two keybinds no-op — and an
    # unattended install must not die on an optional third-party asset
    # (D-59's zero-prompts posture applied to network failure).
    echo "Fetching zellij plugins..."
    ZELLIJ_PLUGIN_DIR="$HOME/.config/zellij/plugins"
    mkdir -p "$ZELLIJ_PLUGIN_DIR"
    # name|url|sha256 — regenerate a pin with:
    #   curl -sL <url> | sha256sum
    ZELLIJ_PLUGINS=(
        "zjstatus.wasm|https://github.com/dj95/zjstatus/releases/download/v0.24.0/zjstatus.wasm|1ccedece1ded62cf3e209be690cdd39ca6fb9e8228ed71a951f6507f9956669b"
        "zellij-autolock.wasm|https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm|69c95607bfd97e075d6762a44fdbc703a82a3c4909dbbbe43952f020487b8ea4"
    )
    for _zp in "${ZELLIJ_PLUGINS[@]}"; do
        _zp_name="${_zp%%|*}"
        _zp_rest="${_zp#*|}"
        _zp_url="${_zp_rest%%|*}"
        _zp_sha="${_zp_rest##*|}"
        _zp_dest="$ZELLIJ_PLUGIN_DIR/$_zp_name"

        # Idempotent: an already-correct file is left alone, so a re-run
        # of install.sh costs no network at all.
        if [[ -f "$_zp_dest" ]] && echo "$_zp_sha  $_zp_dest" | sha256sum -c --status 2>/dev/null; then
            echo "  ✓ $_zp_name (already present, checksum matches)"
            continue
        fi

        # Download to a temp path first so a failed or corrupt fetch can
        # never leave a partial .wasm where zellij would try to load it.
        _zp_tmp="$(mktemp "${TMPDIR:-/tmp}/zellij-plugin-XXXXXX")"
        if ! timeout 120 curl -fsSL -o "$_zp_tmp" "$_zp_url"; then
            echo "  ⚠ $_zp_name: download failed — skipping (zellij runs without it)" >&2
            rm -f "$_zp_tmp"
            continue
        fi
        if ! echo "$_zp_sha  $_zp_tmp" | sha256sum -c --status 2>/dev/null; then
            echo "  ⚠ $_zp_name: SHA256 MISMATCH against the pinned value — refusing to install this asset" >&2
            echo "      expected: $_zp_sha" >&2
            echo "      actual:   $(sha256sum "$_zp_tmp" | cut -d' ' -f1)" >&2
            rm -f "$_zp_tmp"
            continue
        fi
        install -m 0644 "$_zp_tmp" "$_zp_dest"
        rm -f "$_zp_tmp"
        echo "  ✓ $_zp_name"
    done

    # ── Pre-grant zellij plugin permissions ─────────────────────────────
    # WHY THIS IS NOT OPTIONAL POLISH — found live on 2026-08-20:
    # a zellij plugin must be granted permissions before it renders, and
    # zellij asks by drawing an "Allow?(y/n)" prompt INSIDE THE PLUGIN'S
    # OWN PANE. zjstatus's pane is one row tall, so the prompt physically
    # cannot render there. The result is a bar that silently shows
    # nothing, with the plugin loading successfully in the log and no
    # error anywhere a user would look. There is no in-session way to
    # answer a prompt that cannot draw itself.
    #
    # So the grant is seeded here instead. This is a real security
    # decision, made deliberately and narrowly: every plugin listed above
    # is pinned to an exact release AND checksum-verified before it lands
    # on disk, and each grant below is the minimum that plugin needs.
    # zjstatus gets RunCommands only because the bar runs a git command;
    # drop that line if the command widget is ever removed. Do NOT widen
    # these to the full permission set for convenience.
    #
    # Idempotent and non-destructive: entries are appended only when the
    # plugin path is absent, so zellij's own edits to this file (a user
    # granting or revoking something interactively) are preserved.
    echo "Seeding zellij plugin permissions..."
    ZELLIJ_PERM_FILE="$HOME/.cache/zellij/permissions.kdl"
    mkdir -p "$(dirname "$ZELLIJ_PERM_FILE")"
    touch "$ZELLIJ_PERM_FILE"
    # plugin-basename|permission list (space-separated)
    ZELLIJ_PERMS=(
        "zjstatus.wasm|ReadApplicationState ChangeApplicationState RunCommands"
        "zellij-autolock.wasm|ReadApplicationState ChangeApplicationState"
    )
    for _zperm in "${ZELLIJ_PERMS[@]}"; do
        _zperm_name="${_zperm%%|*}"
        _zperm_list="${_zperm#*|}"
        _zperm_path="$ZELLIJ_PLUGIN_DIR/$_zperm_name"

        # Only grant for a plugin that actually landed — a fetch that
        # failed or failed its checksum must not get a standing grant.
        [[ -f "$_zperm_path" ]] || continue

        if grep -qF "\"$_zperm_path\"" "$ZELLIJ_PERM_FILE" 2>/dev/null; then
            echo "  ✓ $_zperm_name (already granted)"
            continue
        fi
        {
            echo "\"$_zperm_path\" {"
            for _p in $_zperm_list; do echo "    $_p"; done
            echo "}"
        } >> "$ZELLIJ_PERM_FILE"
        echo "  ✓ $_zperm_name granted: $_zperm_list"
    done
    echo ""
}

# ── section_hardware ──────────────────────────────────
# NVIDIA package group and limine bootloader steps — both hardware-guarded
# (D-58): NVIDIA only installs when an NVIDIA GPU is detected via lspci;
# limine steps only run when limine is actually the installed bootloader.
# Skipped entirely under --core-only.
section_hardware() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     Hardware-specific setup              ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    if lspci | grep -qi nvidia; then
        echo "NVIDIA GPU detected — installing NVIDIA packages..."
        sudo pacman -Sy --needed --noconfirm "${NVIDIA_PKGS[@]}"
        NVIDIA_INSTALLED=true
    else
        echo "No NVIDIA GPU detected — skipping NVIDIA packages."
        NVIDIA_INSTALLED=false
    fi

    # ── Fallback kernel (2026-07-28 black-screen incident) ──────
    # Deliberately OUTSIDE the NVIDIA guard — a second bootable kernel is
    # worth having whatever the GPU vendor.
    #
    # Ordering is load-bearing: this runs AFTER the NVIDIA block so the DKMS
    # module is already registered when the LTS kernel lands, letting the alpm
    # hook build for it in the same transaction chain; and BEFORE the limine
    # block below so the regenerated limine.conf picks up the new entry.
    # Verified on the reference host: installing linux-lts produced both the
    # nvidia build for 6.18.40-2-lts and its own limine entry, unattended.
    echo ""
    echo "Installing fallback LTS kernel..."
    sudo pacman -Sy --needed --noconfirm "${FALLBACK_KERNEL_PKGS[@]}"

    # ── DKMS integrity guard (2026-07-28 black-screen incident) ──
    # A pacman -Syu installed kernel 7.1.5-arch1-1 but the upstream DKMS
    # alpm hook never built nvidia-open-dkms for it, and nothing reported
    # the gap. With no driver claiming the GPU, Hyprland rendered on
    # simpledrm (the EFI framebuffer) and the kernel oopsed in
    # drm_fb_memcpy — black screen after login, found only at next boot.
    #
    # Two independent defects, both reproduced by this script until now:
    #
    #  1. kernel-modules-hook (AUR_PKGS above) preserves each running
    #     kernel's module tree across upgrades — genuinely useful — but
    #     ships its reaper, linux-modules-cleanup.service, DISABLED. On the
    #     affected machine 13 orphaned trees accumulated (6.8 GB).
    #  2. /usr/share/libalpm/scripts/dkms builds its work list by globbing
    #     every /usr/lib/modules/*/build/. The orphans were complete trees
    #     WITH headers, so none were filtered — the list grew from 1 kernel
    #     to 14, iterated in arbitrary hash order with no priority for the
    #     live kernel, and died before reaching it.
    #
    # kernel-module-verify enumerates kernels by their package-written
    # `pkgbase` marker instead of by directory glob, so orphans cannot starve
    # it, and runs as a PostTransaction hook sorting after 70-dkms-install.
    #
    # It checks BOTH module sources: DKMS registration, and — source-agnostic
    # via `modinfo -k` — that each kernel can actually resolve its NVIDIA
    # module. The second pass matters because Arch has dropped the proprietary
    # kernel modules entirely (nvidia/nvidia-dkms/nvidia-lts are gone as of
    # driver 610); the prebuilt survivors nvidia-open/nvidia-open-lts ship .ko
    # files into usr/lib/modules/<exact-kver>/extramodules/ and register no
    # DKMS module at all. A DKMS-only check passes vacuously on those systems.
    echo ""
    echo "Installing kernel module verification hook..."
    sudo install -Dm755 "$REPO_DIR/system/usr/local/bin/kernel-module-verify" \
        /usr/local/bin/kernel-module-verify
    sudo install -Dm644 "$REPO_DIR/system/etc/pacman.d/hooks/99-kernel-module-verify.hook" \
        /etc/pacman.d/hooks/99-kernel-module-verify.hook

    # Console-app launcher for the xdg wrapper entries. It goes to
    # /usr/local/bin rather than a $HOME path because a .desktop `Exec=` line
    # cannot contain `~` or `$HOME`, and hardcoding /home/<user> would make
    # the entries break for any other username. xdg-open resolves the first
    # Exec word with `command -v`, so an absolute system path always works.
    echo "Installing the terminal-app launcher (open-in-terminal)..."
    sudo install -Dm755 "$REPO_DIR/system/usr/local/bin/open-in-terminal" \
        /usr/local/bin/open-in-terminal

    # `enable` without --now: the reaper deletes module trees for kernels
    # that are not running, which is a boot-time job, not a mid-install one.
    # Guarded + non-fatal, matching the ollama precedent above, so a
    # machine without kernel-modules-hook installed still completes cleanly.
    if systemctl cat linux-modules-cleanup.service &>/dev/null; then
        echo "Enabling linux-modules-cleanup (reaps orphaned kernel module trees)..."
        sudo systemctl enable linux-modules-cleanup.service \
            || echo "  ⚠ linux-modules-cleanup enable failed" >&2
    else
        echo "kernel-modules-hook not installed — skipping module-tree reaper."
    fi

    echo ""
    if command -v limine-install &>/dev/null; then
        echo "Updating limine bootloader entries..."
        # Pitfall 5/WR-08: back up before deleting, and use `rm -f` so a
        # re-run where limine.conf is already gone doesn't abort the script
        # under set -e. Never a bare `rm` without a prior backup.
        if [[ -f /boot/limine/limine.conf ]]; then
            sudo cp /boot/limine/limine.conf /boot/limine/limine.conf.bak
        fi
        sudo rm -f /boot/limine/limine.conf
        sudo limine-install --fallback
        sudo limine-update
        sudo limine-scan
    else
        echo "limine not detected — skipping bootloader update."
    fi
}

# ── section_personal ──────────────────────────────────
# Hardcoded personal config (git identity, timezone) — not meaningful (and
# potentially wrong) inside a disposable container/VM, so this section is
# skipped under --core-only (D-61).
# ── section_security ──────────────────────────────────
# Quick task 260827-np1. Places the three root-owned pieces the Security
# Center needs and enables the units that feed it. Runs in the core
# section (not behind --core-only) because the shell's Security page is
# part of the core rice and renders wrong without these.
#
# Nothing here turns the firewall ON. Installing a ruleset and enabling
# a packet filter are different acts: the file is placed so the pane's
# "Enable firewall" button has something valid to load, and the operator
# makes the call. An installer that silently starts filtering a machine's
# traffic is not a thing this repo should do unattended.
section_security() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     Security Center                      ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    # Root-owned files live under system/ — the same convention
    # kernel-module-verify and open-in-terminal already use, installed
    # with `sudo install -Dm...` rather than stowed.
    local SRC="$REPO_DIR/system"

    # ── 1. Privileged helper + snapshot producer ──
    # Deliberately NOT stowed. These are pkexec targets; a root-executed
    # script living inside a user-writable dotfiles tree is a local
    # privilege escalation, not a convenience. They are COPIED to
    # root-owned /usr/local/lib and re-copied on every install so an
    # edit in the repo actually ships.
    echo "Installing privileged helpers to /usr/local/lib/security-center..."
    sudo install -Dm755 -o root -g root \
        "$SRC/usr/local/lib/security-center/security-action" \
        /usr/local/lib/security-center/security-action
    sudo install -Dm755 -o root -g root \
        "$SRC/usr/local/lib/security-center/smart-snapshot" \
        /usr/local/lib/security-center/smart-snapshot
    sudo install -d -o root -g root -m 0755 /var/lib/security-center

    # ── 2. polkit action ──
    # Names the action so the auth dialog says what is about to happen
    # instead of pkexec's generic "run a program as another user".
    sudo install -Dm644 -o root -g root \
        "$SRC/usr/share/polkit-1/actions/org.aorus.securitycenter.policy" \
        /usr/share/polkit-1/actions/org.aorus.securitycenter.policy

    # ── 3. Firewall ruleset (placed, not activated) ──
    # Back up whatever is there first — on a fresh Arch box that is the
    # stock file, and the stock file is what we are deliberately
    # replacing (its `forward policy drop` chain breaks Docker/k3d; see
    # system/etc/nftables.conf's header for the measurement).
    if [[ -f /etc/nftables.conf ]] && ! cmp -s "$SRC/etc/nftables.conf" /etc/nftables.conf; then
        echo "Backing up existing /etc/nftables.conf -> /etc/nftables.conf.pre-dotfiles"
        sudo cp -n /etc/nftables.conf /etc/nftables.conf.pre-dotfiles
    fi
    sudo install -Dm644 -o root -g root "$SRC/etc/nftables.conf" /etc/nftables.conf

    # Validate what we just placed. A ruleset with `input policy drop`
    # and a syntax error is how a machine loses its network, so a bad
    # file must fail the install loudly here rather than at the moment
    # the operator clicks Enable.
    if ! sudo nft -c -f /etc/nftables.conf; then
        echo "install.sh: /etc/nftables.conf failed validation — refusing to continue" >&2
        exit 1
    fi
    echo "  /etc/nftables.conf installed and validated (NOT enabled — enable it from Settings → Security)"

    # ── 4. Units ──
    sudo install -Dm644 -o root -g root \
        "$SRC/etc/systemd/system/smart-snapshot.service" \
        /etc/systemd/system/smart-snapshot.service
    sudo install -Dm644 -o root -g root \
        "$SRC/etc/systemd/system/smart-snapshot.timer" \
        /etc/systemd/system/smart-snapshot.timer
    sudo systemctl daemon-reload

    # smartd: the root-side monitor the operator chose as the privilege
    # strategy. It watches SMART and warns; the timer below is what makes
    # its subject matter renderable, since smartctl needs root even when
    # smartd is running.
    sudo systemctl enable --now smartd.service     || echo "  ⚠ smartd enable failed" >&2
    sudo systemctl enable --now smart-snapshot.timer || echo "  ⚠ smart-snapshot.timer enable failed" >&2
    # Prime the snapshot so the pane has data on first open instead of an
    # empty device list for up to 15 minutes.
    sudo systemctl start smart-snapshot.service    || echo "  ⚠ first SMART snapshot failed" >&2

    # clamav signatures. Without this the scanner loads an empty database
    # and reports every scan clean — a false all-clear, worse than no
    # scanner at all.
    echo ""
    echo "Fetching ClamAV signatures (first run downloads ~300 MB)..."
    sudo freshclam || echo "  ⚠ freshclam failed — run 'sudo freshclam' before trusting a scan" >&2
    sudo systemctl enable --now clamav-freshclam.service || echo "  ⚠ freshclam timer enable failed" >&2

    # rkhunter's baseline. Without --propupd its first run reports every
    # system binary as "changed" against an empty baseline.
    sudo rkhunter --propupd --nocolors >/dev/null 2>&1 || true
}

section_personal() {
    echo ""
    echo "Configuring git..."
    git config --global user.name yahiaEng
    git config --global user.email eng-yahia-tarek@outlook.com

    echo ""
    echo "Setting timezone..."
    sudo timedatectl set-timezone Africa/Cairo
}

# ── verify_packages ───────────────────────────────────
# Hard-fail post-install verification (D-63/D-64/D-65): takes a nameref to
# a package array, checks each with `pacman -Q`, prints a full [OK]/[MISS]
# table, and exits nonzero the instant any package in the verified set is
# missing — exactly what would have caught the adw-gtk3 ghost. No
# warn-and-continue path.
verify_packages() {
    local -n pkgs_ref="$1"
    local missing=() name

    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     Verifying installed packages         ║"
    echo "╚══════════════════════════════════════════╝"

    for name in "${pkgs_ref[@]}"; do
        if pacman -Q "$name" &>/dev/null; then
            printf '  [OK]   %s\n' "$name"
        else
            printf '  [MISS] %s\n' "$name"
            missing+=("$name")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        echo ""
        echo "install.sh: ${#missing[@]} package(s) failed to install: ${missing[*]}" >&2
        exit 1
    fi

    echo ""
    echo "All ${#pkgs_ref[@]} packages verified installed."
}

# ── Main ──────────────────────────────────────────────
section_core_rice

# Security Center (quick task 260827-np1) — inside the core set, not
# behind --core-only: the shell ships a Settings → Security page, a
# dashboard tab and a bar capsule, and all three render wrong without the
# root-side helpers and the SMART snapshot timer this section installs.
section_security

if [[ "$CORE_ONLY" != "true" ]]; then
    section_hardware
    section_personal
fi

# Verify exactly the packages the selected sections installed: the core
# set always; the NVIDIA group additionally, but only when section_hardware
# actually installed it (a --core-only run verifies the core set only —
# D-65).
VERIFY_PKGS=("${PACMAN_PKGS[@]}" "${AUR_PKGS[@]}")
if [[ "$CORE_ONLY" != "true" ]]; then
    VERIFY_PKGS+=("${FALLBACK_KERNEL_PKGS[@]}")
    if [[ "$NVIDIA_INSTALLED" == "true" ]]; then
        VERIFY_PKGS+=("${NVIDIA_PKGS[@]}")
    fi
fi
verify_packages VERIFY_PKGS

# ── Kernel module soundness gate (2026-07-28 incident) ──────
# Packages being present is not the same as every installed kernel being able
# to load its driver — that gap is exactly what caused the black screen. Run
# the guard once here so a fresh install reports its own soundness BEFORE the
# first reboot, while the operator is still watching.
#
# Non-fatal by design: this script runs under `set -euo pipefail`, so an
# unguarded non-zero exit would abort AFTER everything is already installed,
# turning a useful warning into a confusing failure. Same `|| echo "  ⚠ ..."`
# precedent as the ollama enable in section_core_rice.
#
# Skipped under --core-only: no hardware section ran, so there is no
# kernel/driver work to check.
if [[ "$CORE_ONLY" != "true" ]] && command -v kernel-module-verify &>/dev/null; then
    echo ""
    echo "Verifying kernel modules for all installed kernels..."
    kernel-module-verify \
        || echo "  ⚠ kernel module verification FAILED — see above before rebooting" >&2
fi

echo "Next steps:"
echo "  1. Run './stow.sh' to set up symlinks"
echo "  2. One-time Node provisioning (fish shell): open a new fish shell"
echo "     (self-bootstraps fisher + nvm.fish via config.fish), then run"
echo "     'nvm install v24.18.0' to install the pinned default version"
echo "  3. Select 'Hyprland (uwsm-managed)' in your display manager"
echo "  4. Or from TTY: uwsm start hyprland-uwsm.desktop"
