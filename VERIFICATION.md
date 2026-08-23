# 🧪 Fresh-Install Reproduction Verification (INST-03)

This document is the **documented, human-run** graphical VM reproduction
procedure (D-54 — not automated, unlike `verify/container-run.sh`). It is
the final gate proving the whole rice reproduces from a genuinely fresh
Arch Linux system: `install.sh` + `stow.sh` run unattended, Hyprland
actually starts, and a human confirms the fully themed desktop with their
own eyes (D-53).

Two tiers make up INST-03's evidence:

| Tier | What it proves | How it runs | Where |
|------|-----------------|-------------|-------|
| Container (fast iteration) | Package installs + stow + render-only theme parity, headless | `verify/container-run.sh`, rerunnable, keeper artifact | This repo |
| Graphical VM (final gate) | Hyprland actually starts; the full themed desktop is visually confirmed | This document, followed by hand, once per verification cycle | Below |

The container tier **cannot** prove Hyprland starts or that a human sees a
themed desktop — `theme-doctor`'s one remaining session-dependent check
(`gsettings gtk-theme`, D-Bus) legitimately fails headless. That is
exactly what this VM procedure exists to prove.

**Pass condition (unambiguous, D-53):**

> `theme-doctor` exits 0 and reports zero failures — except for entries on
> the pre-authored exemption list in §7 — AND `theme-parity` reports 0
> failures across all render targets AND the human visually confirms the
> themed desktop on the VM's own display.

All three conditions must hold. A tool-only pass without a human visual
confirmation does **not** satisfy INST-03 — same standard Phase 1/2 held
for the live-desktop verdict (D-35 carried forward).

---

## ⚠️ NOPASSWD scoping warning — read before you start

Steps 3 and 5 below configure a `NOPASSWD` sudoers drop-in **inside the
disposable VM only**, so `install.sh`/`stow.sh` can run with zero
interactive prompts (D-59). This is a deliberate, scoped-down convenience
for a throwaway verification environment — it is:

- **Never** committed to this repository (no sudoers/NOPASSWD file
  exists anywhere in this repo's tracked history — verified by a repo
  grep as part of this phase's threat register, T-03-04-NOPASS).
- **Never** copied onto, or left active on, any persistent/real machine.
- Discarded automatically when the VM is deleted at the end of the
  verification cycle (see step 8).

If you are ever tempted to reuse this drop-in on your actual daily-driver
machine to "make sudo less annoying" — don't. It only belongs on the
disposable VM built in step 2.

---

## 1. Host prerequisites

Install the VM tooling on the **host** machine (official `extra` repo,
pacman — no AUR needed for any of this):

```bash
sudo pacman -S --needed qemu-full libvirt virt-install edk2-ovmf dnsmasq
sudo systemctl enable --now libvirtd.socket
sudo usermod -aG libvirt "$USER"
# Log out and back in (or reboot) for the libvirt group membership to
# take effect before continuing.
```

Note: `iptables` (which libvirt's default NAT network, `virbr0`, needs)
is already part of a standard Arch install — there is **no** package
named `iptables-nft`; do not try to install it under that name.

Verify the toolchain landed:

```bash
podman --version        # only needed for the container tier, not this VM tier
qemu-system-x86_64 --version
virsh --version
virt-install --version
systemctl is-active libvirtd.socket
groups | grep -q libvirt && echo "in libvirt group"
```

## 2. Build the "genuinely fresh Arch" VM baseline (D-55)

Download the official Arch Linux installation ISO from
<https://archlinux.org/download/> onto the host, then create a fresh VM
disk and boot the ISO under QEMU/KVM with a `virtio-gpu` display device
(the modern, accelerated default for a Wayland guest — see
03-RESEARCH.md's State of the Art section for why virtio-gpu over
QXL/SPICE):

```bash
virt-install \
  --name dotfiles-verify \
  --memory 4096 \
  --vcpus 2 \
  --disk size=40 \
  --cdrom /path/to/archlinux-YYYY.MM.DD-x86_64.iso \
  --os-variant archlinux \
  --graphics spice \
  --video virtio \
  --network network=default \
  --boot uefi
```

Boot into the live ISO environment, connect to the network
(`iwctl`/DHCP as needed — the default libvirt NAT network provides DHCP
via `dnsmasq`), then run a **minimal** unattended `archinstall` — base
system + NetworkManager + one sudo user, deliberately **no desktop
environment and no AUR helper preinstalled**. This is intentional: it
exercises the `install.sh` paru-bootstrap path from a genuinely bare
system (WR-09), the same as a real first-time user would experience.

```bash
archinstall
# In the menu-driven flow, select:
#   - Minimal profile (no desktop environment)
#   - Bootloader: systemd-boot or grub (either works; limine is not
#     part of this baseline unless you want to also test the limine
#     hardware-guard path in install.sh's section_hardware)
#   - Network configuration: NetworkManager
#   - One user account with sudo privileges
#   - Do NOT select any AUR helper, DE, or additional package group
```

Reboot into the newly-installed system when archinstall finishes.

## 3. Configure passwordless sudo (VM-only — see warning above)

Inside the fresh VM, as the sudo user created by archinstall:

```bash
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/verify-nopasswd
sudo chmod 440 /etc/sudoers.d/verify-nopasswd
```

This removes every interactive sudo password prompt for the remainder of
this procedure (D-59 — strictly zero prompts until the final human visual
check).

## 4. Clone the repo from the real remote (D-56)

```bash
sudo pacman -Sy --needed --noconfirm git
git clone https://github.com/yahiaeng/dotfiles ~/dotfiles
cd ~/dotfiles
```

Cloning from the real remote (not copying files from the host) is
required — it is the only way this run counts as genuine fresh-environment
evidence rather than a dev-machine re-stow (D-56's explicit prohibition).

## 5. Run install.sh (unflagged), then stow.sh

```bash
chmod +x install.sh stow.sh
./install.sh
```

**This VM tier now runs `install.sh` unflagged, reversing D-22-11's own
container-tier precedent for this tier — recorded here, not slipped in.**
`--core-only` skips exactly two sections: `section_hardware` (NVIDIA
packages behind an `lspci` guard, limine bootloader steps behind a
bootloader guard) and `section_personal` (git identity, timezone). Every
package install — including the shell and visualiser packages — lives in
`section_core_rice` and always runs regardless of the flag, and
`verify_packages`'s post-install table hard-fails on that set either way.
**The container tier's scope was already correct and stays
`--core-only`** — do not "helpfully" change the container harness to match
this section; that scope question is settled by D-22-11, not open.

The gap an unflagged run closes: the tracked `system/` tree
(`system/usr/local/bin/kernel-module-verify`,
`system/etc/pacman.d/hooks/99-kernel-module-verify.hook`) is deliberately
not stowed — `install.sh` installs it with `sudo install` inside
`section_hardware`, and its post-install verification is also skipped
under `--core-only`. Neither tier has ever installed it. A VM is a real
machine with a real bootloader, so an unflagged run here proves
`section_hardware`'s non-NVIDIA path and installs `system/` for the first
time in any reproduction proof.

**Reversal, named explicitly (D-61, D-22-11):** `section_personal` writes
a git identity and a timezone, and has been skipped since v1.0 under D-61
as "not meaningful, potentially wrong" in a disposable environment.
Running it here is harmless — the VM is deleted at step 9 — but it IS a
reversal of D-61 for this tier, and this paragraph is that record, not a
silent behavior change.

Because an unflagged run also runs `section_hardware`, the fallback-kernel
package set joins the post-install verification table — so the expected
`All N packages verified installed.` count is **higher** on this VM tier
than on the container tier. Confirm the run still ends with `[OK]` for
every package and `All N packages verified installed.` — any `[MISS]`
line means `install.sh` already exited nonzero (D-63/D-64) and this run
has failed; do not proceed.

```bash
./stow.sh
```

Confirm `stow.sh` completes with no errors and prints
`Dotfiles stowed successfully!` — this also seeds the first-boot theme
baseline (`theme-apply catppuccin`, D-60) so `~/.local/state/theme/`
exists before the first Hyprland login.

## 6. Start Hyprland via uwsm

```bash
uwsm start hyprland-uwsm.desktop
```

(Or select "Hyprland (uwsm-managed)" from a display manager if one is
configured — the minimal archinstall baseline from step 2 has none by
default, so the TTY command above is the expected path here.)

Confirm the current surface inventory all comes up themed — no relogin,
no manual fixups — naming each surface by requirement ID so it can
actually be found on screen:

- The **bar** (QBAR)
- **Notification popups and the notification centre** (QNOTIF)
- The **dashboard drawer**
- **OSD indicators** — volume/brightness/caps-lock (QOSD)
- The **power menu** (QPOWER)
- The **workspace overview**
- The **Media tab**, including its cava audio-reactive ring (QMEDIA)
- The **native QML launcher** (quick task 260822-sht) — replaces the
  retired external launcher and its backend daemon, in-process now
- **Thunar** — unchanged by this milestone's retirements

The bar, the notification surfaces, the OSD, the power menu, the
dashboard, the overview and the launcher are all **one Quickshell
process** — confirming "did they all come up" is checking that one
process's surfaces render correctly, not six separate daemons. Do not
enable any systemd unit for
this: the Quickshell units (`quickshell.service`,
`quickshell-bar-watchdog.service`) deliberately carry no `[Install]`
section so enabling can never write a wants-symlink outside the
repository — `autostart.lua` starts them, and that is the whole
mechanism.

This is the moment the container tier cannot exercise at all.

## 7. Run theme-doctor and theme-parity, save the logs (D-45)

With the live Hyprland session running:

```bash
~/.config/theme-engine/theme-doctor | tee ~/theme-doctor-verify.log
echo "theme-doctor exit: $?"

~/.config/theme-engine/theme-parity | tee ~/theme-parity-verify.log
echo "theme-parity exit: $?"
```

Both commands must exit `0`. `theme-doctor` must report zero failures
**except for entries on the pre-authored exemption list below** —
including the one remaining session-dependent check (`gsettings gtk-theme
= adw-gtk3-dark`) that the container tier cannot exercise, which must
still pass here with no exemption needed.
`theme-parity` must report 0 failures across all 7 render targets — its
half of the bar is unqualified; no exemption row ever applies to it.

### Pre-authored exemption list (D-22-02)

**Authored before any VM run exists to argue with it.** This is the whole
mechanism: writing the list down in advance is what prevents a red line
being rationalised away after it appears on screen. Anything a `theme-doctor`
run reports that is **not** on this list is a real defect, full stop —
not a candidate for a same-day addition. This is the same discipline
`retirement-check`'s registry, `motion-lint`'s exemption list and
`hypr-equivalence-check`'s own `ACCEPTED_ADDITIONS` table all already use
in this repo: the rule is data the tool's reader consults, never prose
someone has to remember to honour.

**This list governs the VM tier only.** The container tier has its own
separate, machine-read allowlist committed next to `container-run.sh` —
the two are never merged, and neither tier's exemptions apply to the
other.

| Check (as `theme-doctor` names it) | Reason it may legitimately differ on a genuinely fresh machine | Source | Permanent / provisional |
|---|---|---|---|
| ~~`hypr-equivalence-check: options.jsonl`~~ (folded into `theme-doctor`, live-session-guarded) | ~~This baseline was captured against Hyprland **0.56.1** (2026-07-28). This dev host already runs **0.56.2**, and a VM built fresh from the official `extra` repo at run time is very likely to differ again. `options.jsonl`'s comparator has **no** accepted-additions mechanism — unlike `binds.json`, which forgives a named, reviewed set of new binds via `ACCEPTED_ADDITIONS` — so any `hyprctl -j getoption` key a newer Hyprland release adds, renames or removes produces an unconditional "present in live only" / "present in baseline only" FAIL with no escape hatch.~~ | `.hypr-baseline/MANIFEST.md:3` (baseline Hyprland version); `hyprctl version` on this host (0.56.2, confirmed live); `hypr-equivalence-check:405-427` (`_compare_options_normalized`'s `b is None` / `l is None` branches, now both routed through `ACCEPTED_OPTION_CHANGES`) | **RESOLVED 2026-08-18** (quick task `260818-ne8`) — see the note below |

**Resolution of the `options.jsonl` row (2026-08-18).** The row named two ways
out; the second was taken. `options.jsonl` now has its own
`ACCEPTED_OPTION_CHANGES` table (`hypr-equivalence-check:366`), the direct
analog of `binds.json`'s `ACCEPTED_ADDITIONS`, consulted by both
no-escape-hatch arms (`:405-427`). It is keyed by `(option-key, kind)` where
kind is `'added'` or `'removed'`, so forgiving an addition never silently
forgives a later removal of the same key; entries are enumerated, never
pattern-matched; a malformed entry exits 2 rather than degrading to the old
fail-open (`:376-385`); and an entry that never fires is reported as stale so
the table cannot rot (`:445-449`).

**The re-capture route was deliberately NOT taken**, and this is the more
important half of the resolution. `.hypr-baseline/MANIFEST.md`'s own 14-10
amendment records why: a re-snapshot overwrites all ~80 records with fresh
live values, including the two `bindm` mouse-field records that 13.1-04 Task 3
explicitly forbade loosening. Re-capturing to clear a version-drift exemption
would have quietly destroyed a deliberate, documented red.

**Measured at resolution:** the drift this row anticipated had not yet fired.
`hyprctl version` = 0.56.2 against a 0.56.1 baseline, and a live run is
`PASS: 3  FAIL: 0` — the 0.56.1 → 0.56.2 bump added, renamed and removed zero
of the 46 tracked keys. (The `int` → `bool` type-key notes come from the
hyprlang → Lua migration, not the version bump, and already normalize.) So the
table ships **empty** and adding it changes no verdict on the current tree,
which is the correctness condition for a preventive mechanism.

Because this repo's own closing lesson from v4.0 is that *a gate that has only
ever been green has not been shown to reject anything*, the mechanism was
exercised against synthetic fixtures before being trusted: an unlisted added
key FAILs (exit 1); an unlisted removed key FAILs (exit 1); a listed added key
is accepted with a note (exit 0); a listed removed key is accepted with a note
(exit 0); an entry filed under the wrong kind does **not** forgive (exit 1);
and a malformed entry exits 2. Both the rejection and the acceptance paths are
proven, not just the green one.

**Operational consequence for the next VM run: this exemption list is now
empty.** It had exactly one row and that row is resolved. Every check a
`theme-doctor` run reports on the VM tier is therefore a real defect with no
exemption available — which is stricter than the tier shipped in Phase 22, and
intentionally so. Version drift in `options.jsonl` is now handled *in the tool*
by a named, reviewed `ACCEPTED_OPTION_CHANGES` entry, which is data the reader
consults, rather than by a prose row someone has to remember to honour. Adding
a new row here still requires authoring it **before** the run that would argue
with it (D-22-02); that rule is unchanged.

No other row is added: `binds.json` already absorbs legitimate new binds
via its own `ACCEPTED_ADDITIONS` table (so a genuine addition there is not
a `theme-doctor` FAIL at all, and needs no exemption here), and
`animations.json`'s leaf/curve comparison was not found to carry an
equivalent version-drift gap. A check with no source-level reason is a
defect, not an exemption — the same rule the container-tier allowlist
(D-22-09) follows.

Copy both log files off the VM (e.g. `scp`, or a shared clipboard/folder
via SPICE) as the machine-readable half of the INST-03 evidence.

## 8. Human visual confirmation (D-53 — non-negotiable)

Look at the VM's own display (the SPICE/QEMU console window, not a
screenshot taken by a script) and confirm, with your own eyes:

- Every listed surface — the bar (QBAR), notification popups and centre
  (QNOTIF), the dashboard drawer, OSD indicators (QOSD), the power menu
  (QPOWER), the workspace overview, the Media tab with its cava ring
  (QMEDIA), the native QML launcher, and Thunar — shows the same theme
  (Catppuccin, by default from the first-boot seed in step 5)
- Switching themes (`Super + Shift + T`) live-updates every visible
  surface instantly, no relogin — the same ten-target standard from
  Phase 1/2
- Nothing is unstyled, blank, or still showing stock GTK defaults

Only once you have personally seen this does INST-03 pass. Record the
verdict (pass/fail, with a note on anything unexpected) alongside the
container-tier logs in the phase SUMMARY.

## 9. Tear down the disposable VM

The VM (and its NOPASSWD drop-in from step 3) is throwaway — delete it
once the verdict is recorded so no persistent NOPASSWD sudo configuration
survives anywhere:

```bash
virsh destroy dotfiles-verify   # on the host, stops the running VM
virsh undefine dotfiles-verify --remove-all-storage
```

---

## Re-running this gate

Both tiers are meant to be re-run whenever `install.sh`, `stow.sh`, or the
theme-engine verification tools change materially:

- **Container tier:** `verify/container-run.sh` — fast, fully scripted,
  re-run as often as needed.
- **VM tier:** repeat steps 2–9 above. Slower and manual by design (D-54)
  — reserved for milestone-level INST-03 sign-off, not every commit.

Before either tier, make sure any local fixes are pushed to the remote
(D-56) — both tiers clone from the real remote, so uncommitted or
unpushed local changes are invisible to them by design.
