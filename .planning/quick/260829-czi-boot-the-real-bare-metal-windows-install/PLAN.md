---
quick_id: 260829-czi
slug: boot-the-real-bare-metal-windows-install
date: 2026-08-29
status: planned
---

# Boot the real bare-metal Windows as the win11-gaming VM

## Objective

Give the `win11-gaming` domain a third mode that boots the operator's real
bare-metal Windows install (`nvme0n1p1..p4`) instead of the scratch qcow2,
so one Windows carries all their games whether it is booted on metal or as
a guest.

## Scope decision (operator, this session)

Option **(b)** — C: as the VM's BOOT disk, not as a data drive. Option (a)
is off the table; do NOT add a `linkable` verb that exposes C: as an extra
drive letter.

Shape: **a third XML** (`vfio/win11-bare.xml`) alongside `win11-install.xml`
and `win11-gaming.xml`, same domain name and UUID. The qcow2 gaming mode
stays intact as a known-good fallback.

## Measured ground truth (this host, 2026-08-29 — not assumed)

| Fact | Value |
|---|---|
| p1..p4 span | sectors 2048 → 1348306943 (contiguous) |
| p5 `Main` starts | 1348308992 — no overlap with the boot set |
| GPT disk GUID | `B8CC3881-9276-4A4B-8808-14F501931C65` |
| p1 ESP | `4dfdc11f-…` type `C12A7328-…` attrs `GUID:63` |
| p2 MSR | `f440b932-…` type `E3C9E316-…` attrs `GUID:63` |
| p3 C: | `2e3b6dd2-…` type `EBD0A0A2-…` |
| p4 recovery | `95873b29-…` type `DE94BBA4-…` attrs `RequiredPartition GUID:63` |
| C: encryption | plain NTFS (`NTFS␣␣␣␣` at offset 3), NOT BitLocker |
| C: + recovery hibernation | `ntfs-3g.probe --readwrite` rc=0 on both |
| Host mounts on nvme0n1 | none (host is nvme1n1p1 `/boot`, nvme1n1p2 `/`) |
| `sgdisk` | NOT installed — `sfdisk --dump` carries type/uuid/name/attrs |

Prototype built and verified before any file was written: the mapped disk
reproduces the disk GUID, all four partition GUIDs, types, names, attrs and
offsets exactly; `bootmgfw.efi`, `bootx64.efi` and the BCD are all readable
through the mapping. Torn down clean, host state unchanged.

## Two findings that shape the implementation

1. **The synthetic GPT must be a replay of the real one, not hand-authored.**
   Windows BCD locates its boot volume by *disk GUID + partition GUID*.
   `vm-main`'s wrapper invents a fresh single-partition table, which is
   correct for a data drive and would be a non-booting disk here. The boot
   wrapper filters `sfdisk --dump` of the real disk: drop the `Main` line,
   pull `last-lba` in, replay everything else verbatim.

2. **The boot disk must be `bus='sata'`, not `bus='virtio'`.** The
   bare-metal Windows has never seen a virtio controller, so `viostor` is
   not a boot-start driver there — a virtio boot disk gives
   `INACCESSIBLE_BOOT_DEVICE` on first power-on. `storahci` is boot-start in
   every stock Windows. Virtio is a later step, after the driver is
   installed inside the guest.

## Tasks

- **T1** — `system/usr/local/lib/vm-drives/vm-drive-action`: add
  `link-boot` / `unlink-boot`, `build_boot_map` / `destroy_boot_map`,
  and extend `status` / `rebuild` / `teardown`. Allowlist the four boot
  PARTUUIDs as constants; take no device from the caller. Safety checks at
  LINK time only — never in `rebuild` (a `die` there strands the operator
  at SDDM with the domain unable to start).
- **T2** — `vfio/win11-bare.xml`: copy of the gaming XML with `vda`
  replaced by `/dev/mapper/vm-winboot` on SATA at boot order 1, same
  `<name>` and `<uuid>`, ISOs dropped.
- **T3** — QML: the `windows` catalogue note now reads "not linkable by
  design", which this task makes false. Correct it to point at bare-metal
  mode. Do NOT add a mode-switch UI — `install`/`gaming` have none either;
  modes switch by `virsh define`.
- **T4** — `docs/vfio-passthrough.md`: document the third mode, the
  `powercfg /h off` requirement, and the activation/Fast-Startup costs.

## Out of scope

- A mode-switch UI (the existing two modes switch by `virsh define`).
- Exposing C: as a data drive.
- Switching the boot disk to virtio.
- Enabling sshd (offered repeatedly, declined).
