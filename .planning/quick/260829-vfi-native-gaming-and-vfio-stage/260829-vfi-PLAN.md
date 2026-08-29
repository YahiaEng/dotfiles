---
plan_id: 260829-vfi
mode: quick
status: planned
date: 2026-08-29
---

# 260829-vfi — Native gaming hardening, and a staged single-GPU VFIO passthrough VM

Operator asked for an Omarchy-style persistent Windows 11 in Docker, "mainly to
play League of Legends", with no sound/network/mouse/NVIDIA pitfalls and every
performance trick available. Measurement redirected the task before planning.

## What measurement changed (all verified on this host, none assumed)

- **League of Legends is unreachable in any VM.** Vanguard blocks Wine, Proton
  and every VM as of patch 26.8 (2026). The Docker/QEMU route cannot ever run
  it. Not a config gap — the anti-cheat's stated design.
- **The host already dual-boots Windows 11.** `/boot/limine.conf` carries a
  `/Windows` entry -> `EFI/Microsoft/Boot/bootmgfw.efi`; Windows lives on
  `nvme1n1p3` (641.9G NTFS) with its ESP on `p1` and recovery on `p4`. So LoL
  already works today by rebooting. Nothing needs building for it.
- **`dockur/windows` cannot accelerate 3D.** Its GPU option maps `/dev/dri`
  (Intel iGPU path); NVIDIA mapping is unreliable and undocumented. Omarchy's
  feature is a noVNC desktop — good for Windows *apps*, never a gaming VM.
- **AMD-V is OFF in firmware.** `svm` absent from `/proc/cpuinfo`, `/dev/kvm`
  missing, no kvm modules. Blocks every VM path until the operator flips
  `SVM Mode` in UEFI. Track 2 is therefore written but **cannot be tested**.
- **The IOMMU topology is unusually good** (22 groups, IOMMU already active):

  | Group | Contents | Use |
  |---|---|---|
  | 16 | `07:00.0` RTX 3070 + `07:00.1` its HDMI audio | pass as a pair |
  | 20 | `09:00.3` CPU USB controller — **keyboard + mouse + USB audio** | pass; native input AND sound in one device |
  | 21 | `09:00.4` onboard HD audio (current default sink) | optional second audio path |
  | 15 | chipset USB + SATA + both NVMe + Ethernet + WiFi | tangled — never touch |

  Group 20 carrying all three input/audio devices is what kills the mouse,
  sound and USB-hotplug pitfalls outright — no evdev bridging, no scream, no
  pulseaudio tunnel.
- **No iGPU** (Ryzen 5 5600X). The 3070 is the only display adapter, so
  passthrough is necessarily *single-GPU*: the host session must be torn down
  for the VM's lifetime and restored after. That also means **vfio-pci must NOT
  be bound at boot** — the usual `modprobe.d` device-id pin would leave the host
  with no GPU and no display at all. Binding happens at VM start, in a hook.

## Operator decisions (locked before planning)

- **D-1 — scope.** Operator selected *Harden native gaming* + *Single-GPU VFIO
  gaming VM*. The dockur/windows Docker box was offered and **declined**.
- **D-2 — VM disk.** Default to a **separate qcow2 image**. Raw-passthrough of
  the existing Windows install (`nvme1n1`) is faster and would give one Windows
  bootable both ways, but risks activation resets and NTFS corruption via Fast
  Startup. Documented as an opt-in upgrade; **not** built without approval.

## Task 1 — Native gaming packages into install.sh

**Files:** `install.sh`

Every name verified against the live repos first (this repo has a scar from
`adw-gtk3`, a name that never existed). Rejected as **not in official repos**:
`vkbasalt`, `lib32-vkbasalt`, `steam-native-runtime`, `bridge-utils`,
`iptables-nft` (the last is a *provide* of `iptables`, already installed).

Add to `PACMAN_PKGS`: `gamescope` (extra), `protontricks` (extra),
`wine-staging` (extra), `winetricks` (extra), `lib32-mangohud` (multilib),
`lib32-gamemode` (multilib).

`wine-staging` **Conflicts With: wine** — add exactly one, never both.
Already present and not re-added: steam, lutris, gamemode, mangohud,
heroic-games-launcher-bin, protonup-qt, lib32-nvidia-utils,
lib32-vulkan-icd-loader.

## Task 2 — `gaming` stow package: MangoHud, gamemode, and a launch wrapper

**Files:** new `gaming/` stow package, `stow.sh` PACKAGES list

- `gaming/.config/MangoHud/MangoHud.conf` — frametime graph, 1% lows, CPU/GPU
  power+temp, VRAM. Off by default (`no_display=1`), toggled with a keybind.
- `gaming/.config/gamemode.ini` — `performance` governor while a game runs,
  renice, ioprio, and the NVIDIA/`end` restore.
- `gaming/.local/bin/gamerun` — one wrapper carrying the env tuning, so the
  vars stay *off* the session-wide environment where they would apply to
  Hyprland and every desktop app. `~/.local/bin` is already on PATH via
  `fish_add_path` in `fish/.config/fish/config.fish`.

Env the wrapper sets, each justified rather than cargo-culted:
`__GL_SHADER_DISK_CACHE=1` + `__GL_SHADER_DISK_CACHE_SIZE` (large, on the
SN850X) + `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` — kills recompilation
stutter; `PROTON_ENABLE_NVAPI=1` + `PROTON_HIDE_NVIDIA_GPU=0` — DLSS/Reflex;
`VKD3D_CONFIG=dxr11` — DX12 raytracing; `DXVK_STATE_CACHE_PATH`; `MANGOHUD=1`;
`RADV_*` deliberately absent (AMD-only, would be noise on an NVIDIA host).

## Task 3 — Host tuning that actually measures as a win

**Files:** `system/etc/sysctl.d/99-gaming.conf`,
`system/etc/modprobe.d/nvidia-gaming.conf`, `install.sh`

- `kernel.split_lock_mitigate=0` — currently **1** (measured). Stops the kernel
  throttling processes that trip split locks; a real and well-documented
  gaming win.
- `vm.max_map_count` is **already 1048576** (measured) — deliberately NOT set.
  Adding it would be a no-op dressed up as a tuning win.
- `options nvidia NVreg_UsePageAttributeTable=1` — better CPU access to GPU
  memory. `NVreg_InitializeSystemMemoryAllocations=0` — skips zeroing system
  memory allocations, less overhead and more usable VRAM. Both apply to
  `nvidia-open-dkms`, which is what is installed here.
- `nvidia-drm.modeset=1` already present in `limine.conf` cmdline — not touched.

Installed with `sudo install -Dm644` in `section_hardware`, matching the
existing `system/` convention (nftables, pacman hooks, security-center).

## Task 4 — Single-GPU VFIO passthrough, staged

**Files:** `system/etc/libvirt/hooks/qemu`,
`system/usr/local/bin/vfio-gpu-bind`, `system/usr/local/bin/vfio-gpu-unbind`,
`system/etc/modprobe.d/vfio.conf`, `vfio/win11-gaming.xml`,
`docs/vfio-passthrough.md`, `install.sh`

- **No boot-time device-id binding.** `modprobe.d/vfio.conf` carries the
  `softdep` ordering only. Pinning `10de:2484` at boot would blank the host.
- **Hook** `/etc/libvirt/hooks/qemu` dispatches on `$1=win11-gaming`:
  - `prepare/begin` -> `systemctl stop sddm` (SDDM is the DM here; Hyprland
    runs under it as `wayland-wm@hyprland.desktop.service`), wait for the
    session to drop, unbind `nvidia_drm nvidia_modeset nvidia_uvm nvidia`,
    bind `vfio-pci` to `07:00.0` + `07:00.1`.
  - `release/end` -> reverse: unbind vfio-pci, reload nvidia modules, restart
    sddm.
  - Every step guarded and logged to `/var/log/vfio-hook.log`, because a wrong
    step here costs the operator their display.
- **Domain XML** `win11-gaming.xml`: Q35 + OVMF UEFI + swtpm TPM 2.0 (both
  mandatory for Windows 11), host-passthrough CPU with 4c/8t pinned (2 cores
  left for the host), hugepages, hyperv enlightenments, `<kvm><hidden/>`,
  virtio disks with an iothread, and PCI hostdevs for groups 16, 20, 21.
  **No emulated video, no SPICE** — the physical monitor is the display.
- Packages: `virt-manager`, `swtpm`, `dnsmasq` (verified extra). `libvirt`,
  `qemu-full` and `edk2-ovmf` are **already installed** — measured, not assumed.

## Verification reality

Track 1 is testable now. Track 2 is **hard-blocked on the BIOS SVM toggle** and
cannot be exercised from this session at all — no `/dev/kvm` exists. Per the
"checklist beats self-verification" rule, Track 2 ships with a numbered
operator checklist in `docs/vfio-passthrough.md` naming exactly what was not
verified, rather than a claim that it works.
