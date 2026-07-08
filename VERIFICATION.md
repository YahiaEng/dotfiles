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
themed desktop — `theme-doctor`'s session-dependent checks (running
walker/elephant processes, `gsettings`, D-Bus) legitimately fail headless.
That is exactly what this VM procedure exists to prove.

**Pass condition (unambiguous, D-53):**

> `theme-doctor` exits 0 (all checks pass, including the session-dependent
> ones) AND `theme-parity` reports 0 failures AND the human visually
> confirms the themed desktop on the VM's own display.

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

## 5. Run install.sh --core-only, then stow.sh

```bash
chmod +x install.sh stow.sh
./install.sh --core-only
```

Confirm the run ends with `install.sh`'s post-install verification table
printing `[OK]` for every package and `All N packages verified installed.`
— any `[MISS]` line means `install.sh` already exited nonzero (D-63/D-64)
and this run has failed; do not proceed.

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

Confirm walker, elephant, waybar, swaync, and Thunar all come up themed
— no relogin, no manual fixups. This is the moment the container tier
cannot exercise at all.

## 7. Run theme-doctor and theme-parity, save the logs (D-45)

With the live Hyprland session running:

```bash
~/.config/theme-engine/theme-doctor | tee ~/theme-doctor-verify.log
echo "theme-doctor exit: $?"

~/.config/theme-engine/theme-parity | tee ~/theme-parity-verify.log
echo "theme-parity exit: $?"
```

Both commands must exit `0`. `theme-doctor`'s summary line must read
`Summary: N passed, 0 failed` — including the session-dependent checks
(`walker process running`, `elephant process running`, `gsettings
gtk-theme = adw-gtk3-dark`, `elephant listproviders responds`) that the
container tier cannot exercise. `theme-parity` must report 0 failures
across all 7 render targets.

Copy both log files off the VM (e.g. `scp`, or a shared clipboard/folder
via SPICE) as the machine-readable half of the INST-03 evidence.

## 8. Human visual confirmation (D-53 — non-negotiable)

Look at the VM's own display (the SPICE/QEMU console window, not a
screenshot taken by a script) and confirm, with your own eyes:

- Waybar, swaync, walker, wlogout, and Thunar all show the same theme
  (Catppuccin, by default from the first-boot seed in step 5)
- Switching themes (`Super + Shift + T`) live-updates every visible app
  instantly, no relogin — the same ten-target standard from Phase 1/2
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
