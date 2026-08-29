---
quick_id: 260829-vfi
title: Native gaming hardening, and a staged single-GPU VFIO passthrough VM
status: complete
completed: 2026-08-29
commits: [370b139c, 94dddf99, 34eb07ae, 76c9478a]
operator_decision: "Harden native gaming + Single-GPU VFIO gaming VM; dockur/windows Docker box declined"
gates: "bash -n 4/4; shellcheck -S warning 4/4 clean; virt-xml-validate PASS; gamerun all 6 branches exercised live; stow gaming OK"
---

# 260829-vfi — SUMMARY

## The request's premise was false, and measuring said so before any code

Asked for an Omarchy-style persistent Windows 11 in Docker, "mainly to play
League of Legends". Three measurements, taken before writing anything, each
independently killed that plan:

1. **Vanguard blocks every VM.** Wine, Proton and all virtual machines, as of
   patch 26.8 (2026). Not a config gap — the anti-cheat's design. No amount of
   `<kvm><hidden/>` touches it; that setting defeats a 2020 *driver* check.
2. **`dockur/windows` has no 3D.** Its GPU option maps `/dev/dri`, the Intel
   iGPU path; NVIDIA mapping is unreliable and undocumented. Omarchy's feature
   is a noVNC desktop — fine for Windows *apps*, never a gaming VM. So even
   built perfectly it would not have run any 3D game, let alone LoL.
3. **The host already dual-boots Windows 11.** `/boot/limine.conf` carries a
   `/Windows` entry -> `EFI/Microsoft/Boot/bootmgfw.efi`; Windows is on
   `nvme1n1p3` (641.9 GB NTFS, ESP on `p1`, recovery on `p4`). **The stated
   goal was already solved on this machine before the task began.**

The third is the one that matters most and was the cheapest to find — it came
from `lsblk` plus reading the bootloader config. Had the Docker box been built
as asked, it would have been a working deliverable that could not do the one
thing it was requested for, on a machine that could already do it.

## Two hardware facts reshaped the VM half

**AMD-V is off in firmware.** `svm` absent from `/proc/cpuinfo`, no `/dev/kvm`,
no kvm modules. Every VM path is hard-blocked behind a UEFI toggle only the
operator can flip, so Track 2 is written and staged but **exercised nowhere**.

**There is no iGPU.** The 5600X is not a `G` part and `lspci` shows exactly one
display adapter. That makes passthrough necessarily single-GPU, which inverts
the standard advice: **the `options vfio-pci ids=…` line every tutorial tells
you to add would bind the only display adapter at boot and leave this machine
black.** `vfio.conf` therefore carries module ordering only, and says so at
length in the file, in `install.sh` at the install site, and in the docs —
three places, because it is the one edit that turns this from working into
unbootable.

## The IOMMU topology did most of the design work

| Group | Contents | Consequence |
|---|---|---|
| 16 | RTX 3070 + its HDMI audio, alone | clean pair, no ACS override needed |
| **20** | CPU USB controller — **keyboard + mouse + USB audio** | one passthrough gives native input AND sound |
| 21 | onboard HD audio, alone | the analog jack, passed too |
| 15 | chipset USB, SATA, both NVMe, NIC, WiFi | tangled, untouched |

Group 20 is why the four pitfalls named in the request do not arise here.
Keyboard, mouse and a USB DAC all sit on one isolated controller, so there is
no evdev bridging, no pointer-capture hotkey, no Scream, no audio tunnel. The
answer was in the group listing, not in configuration effort. The *other*
controller (`02:00.0`) keeps input devices on the host, so a failed teardown
still leaves a usable keyboard — checked deliberately, because the recovery
path matters more than the happy path here.

## Measurement caught a real error mid-build

`NVreg_UsePageAttributeTable=1` — the single most-copied line in NVIDIA tuning
guides — **is not a parameter of the installed driver.** `modinfo -p nvidia`
against `nvidia-open-dkms 610.57.04` does not list it. Writing it would have
produced a modprobe error or a silently ignored line, and either way a tuning
claim with nothing behind it. Only `NVreg_InitializeSystemMemoryAllocations`
is confirmed present; it ships with its security tradeoff stated inline rather
than buried, because it is a real one.

Same discipline on the sysctls: both values shipped were **read first** and
move a measured non-default (`split_lock_mitigate` 1→0,
`compaction_proactiveness` 20→0). The famous `vm.max_map_count` is
deliberately **absent** — already 1048576 here, so writing it would have been
a no-op presented as a tuning win, and would rot the day the default moves.

And on packages, applying this repo's own `adw-gtk3` scar: every name was
checked with `pacman -Si` first. Four were rejected as not existing in the
official repos — `vkbasalt`, `lib32-vkbasalt`, `steam-native-runtime` (AUR),
`bridge-utils` (dropped from Arch) — and `iptables-nft` turned out to be a
*Provides* of `iptables`, not a package at all.

## A reproducibility gap found on the way

`qemu-full`, `libvirt` and `edk2-ovmf` were already on the host with install
reason "Explicitly installed" while appearing **nowhere** in `install.sh` —
exactly the host-only state the project constraint forbids. A fresh install
would have come up without them. Now listed.

## Running the code found a defect that reading it did not

`gamerun --gamescope garbge` reported "gamescope not installed" because the
binary lookup ran before argument validation. A typo is the caller's error and
is true regardless of what is installed, so the message sent the reader to fix
the wrong thing. Reordered. Found by exercising both branches, not by review.

## Design choices most likely to be "fixed" later by someone who has not measured

- **8 vCPUs, not 12.** Cores 0 and 1 are held back for the host, the emulator
  thread and the iothread. Handing the guest all 6 cores makes the emulator
  compete with the vCPUs it serves and frametimes get *worse*.
- **Pinning pairs `n`/`n+6`**, read from `thread_siblings_list` on this host
  rather than assumed, so each guest core lands on a real SMT sibling pair.
- **`release/end`, not `stopped/end`** for the restore hook: `stopped` fires
  while libvirt still holds the device and races the nvidia rebind.
- **`vfio-gpu-unbind` is deliberately not `set -e`** and runs
  `systemctl start sddm` unconditionally. A half-restored driver with a running
  display manager is recoverable; a clean early exit that never restarted SDDM
  is not.

## What is verified, and what is not

**Verified:** `bash -n` on all four scripts; `shellcheck -S warning` clean on
all four; `virt-xml-validate` passes the domain against libvirt's own schema;
all six `gamerun` branches exercised live (plain, `--no-gamemode`, `--no-hud`,
`--hud`, `--fsr`, both `--gamescope` failure modes); `stow gaming` links
cleanly and `gamerun` resolves on PATH; hook dispatch confirmed to no-op for a
non-target guest.

**Not verified, and cannot be from here:**

1. Nothing VM-side runs — there is no `/dev/kvm` until SVM is enabled in UEFI.
2. The GPU teardown/restore cycle is untested. It is the highest-risk step and
   the one that can cost the operator their display.
3. Windows 11's acceptance of the Secure Boot + `tpm-crb` pair. Schema-valid
   only proves libvirt accepts the XML, not that the installer accepts the TPM.
4. **No package or `/etc` file was installed.** `sudo` requires a password in
   this session (`sudo -n` refused), so everything is staged in the repo and
   nothing on the host changed except the stowed `gaming` package.

`docs/vfio-passthrough.md` carries all of this as a numbered operator
checklist with the untestable steps marked, rather than a claim that it works.

## Open, deliberately

- Raw-passthrough of the existing Windows install was **not** built. It is the
  fastest storage option and would give one Windows bootable both ways, but it
  changes the hardware hash Windows activation keys on and risks NTFS damage
  via Fast Startup. Documented as opt-in with an explicit ask-first warning.
- `vkbasalt` was dropped rather than routed to AUR: it is image quality, not
  performance, and did not justify an AUR dependency in a request about speed.
