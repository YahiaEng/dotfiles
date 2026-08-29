---
quick_id: 260829-czi
slug: boot-the-real-bare-metal-windows-install
date: 2026-08-29
status: complete
commits: [67e6efad, 9b3d209e, 65a1478f, ed575521]
---

# Boot the real bare-metal Windows as the win11-gaming VM

## What shipped

A third shape of the `win11-gaming` domain — `vfio/win11-bare.xml` — that
boots the operator's real bare-metal Windows install instead of a qcow2
guest, backed by two new helper verbs (`link-boot`, `unlink-boot`) and one
that closes a pre-existing gap (`sync-disks`).

Operator picked option (b) (C: as the VM's BOOT disk) over option (a) (C: as
a data drive), and the third-XML shape over replacing gaming mode — so the
working qcow2 passthrough config survives as a fallback.

## The finding that shaped the implementation

**The synthetic GPT had to be a replay of the real one, not an invented
table.** `build_main_map` writes a fresh single-partition GPT with random
disk and partition GUIDs, which is correct for a data drive and would have
produced a non-booting disk here: Windows BCD identifies its boot volume by
*disk GUID + partition GUID*. Invent either and `bootmgfw` cannot find
`\Windows`.

So `build_boot_map` filters the real disk's own `sfdisk --dump` — drops the
`Main` line, pulls `last-lba` in to the truncated size — and reproduces every
type GUID, unique GUID, partition name and attribute flag byte-for-byte,
including `RequiredPartition` on the recovery partition, which is what keeps
Windows from giving it a drive letter.

This was found by reading `vm-main`'s builder and asking what BCD keys on,
not by a failed boot.

## The second finding, which would have cost a boot

**`bus='sata'`, not `bus='virtio'`.** The bare-metal Windows has never seen a
virtio controller, so `viostor` is not a boot-start driver in its registry —
a virtio boot disk gives `INACCESSIBLE_BOOT_DEVICE` on first power-on.
`storahci` is boot-start in every stock Windows.

Consequence stated rather than hidden: the data drives are still on virtio,
so the first bare-metal boot shows C: only. `virtio-win.iso` is attached for
exactly that.

## A pre-existing gap this task had to close

`virsh define` replaces the domain definition wholesale, and the linked data
drives are in **none** of the three XML files — they are added by
`attach-device --config` at link time. Measured on the live domain: `vdb` and
`vdc` were present in `dumpxml --inactive` but absent from `win11-gaming.xml`.
So every mode switch silently dropped them while `/var/lib/vm-drives/linked`
still said "linked", and the guest would boot without its drives for a reason
the operator could not see.

That predates this task and bites `install`↔`gaming` too. `sync-disks`
re-attaches whatever the state file records, idempotently.

## Measured before any file was written

| Fact | Value |
|---|---|
| p1..p4 span | sectors 2048 → 1348306943, contiguous |
| p5 `Main` starts | 1348308992 — no overlap |
| GPT disk GUID | `B8CC3881-9276-4A4B-8808-14F501931C65` |
| C: encryption | plain NTFS (`NTFS␣␣␣␣` at offset 3), not `-FVE-FS-` |
| C: + recovery hibernation | `ntfs-3g.probe --readwrite` rc=0 on both |
| Host mounts on nvme0n1 | none |
| `sgdisk` | not installed; `sfdisk --dump` carries type/uuid/name/attrs |

A throwaway prototype was built, verified and torn down *before* the helper
was edited: the mapped disk reproduced the disk GUID, all four partition
GUIDs, types, names, attrs and offsets exactly, and `bootmgfw.efi`,
`bootx64.efi` and the BCD were all readable through the mapping.

## Verified live

- `link-boot` → exit 0; `status` reports `boot=linked boot_mapped=yes`.
- `sfdisk -l /dev/mapper/vm-winboot` shows all four partitions with the real
  disk's identifier and correct type names.
- `virsh define vfio/win11-bare.xml` → accepted; `virt-xml-validate` passes.
- `sync-disks` re-attached both data drives; resulting domain is
  `sda`(sata, boot=1)=`vm-winboot`, virtio-win cdrom, `vdb`=Storage,
  `vdc`=`vm-main`, 4 PCI + 1 USB hostdev, same UUID.
- Settings page opened via `qs ipc call settings openPage virtualization` —
  instantiated with **zero** new log lines. That is the only instrument that
  sees a load error in a lazily-loaded surface.

Gates: colour-lint 581/0, settings-index-check 199/0 (was 197/1 — the new row
needed a RowIndex entry), motion-lint 820/0, transparent-lint 196/0,
button-lint 9/0, singleton-prop-check 1/0, qml-import-check 0 unresolved/195,
stow-link-check 1/0, `bash -n` clean, `virt-xml-validate` passes.

`quickshell-doctor` 27/1. The one failure is `bar-reserved-zone-stability`
(delta=56 vs 48 declared in `Design.qml`) — the horizontal bar's reserved
zone from 260829-2ov. That gate reads `Design.qml`, `bar-visibility.sh` and
live compositor state; this task touches none of them.

## NOT verified — operator checklist

The VM was deliberately **not started**. Starting it tears the desktop down
and ends this session.

1. `sudo virsh start win11-gaming` — the real Windows should boot on the
   RTX 3070. **This is the risky one.** If it stops at a recovery screen,
   the fallback is `virsh define ~/dotfiles/vfio/win11-gaming.xml` +
   `sync-disks`, which restores the working qcow2 guest.
2. Inside Windows, **once**: `powercfg /h off` as administrator. Until this
   is done, alternating metal/guest boots can corrupt C:.
3. Expect only C: on the first boot. Install virtio drivers from the
   attached `virtio-win.iso`, then Storage and Main appear.
4. Expect a reactivation prompt; the digital licence re-applies it.
5. Settings → Virtualization: confirm the Windows C: row now reads "the VM's
   boot disk in bare-metal mode" and the new "Bare-metal mode" row is
   present. A hot reload can serve a stale settings page, so this may need a
   shell restart to show.
6. Confirm the round trip: shut down, redefine `win11-gaming.xml`, run
   `sync-disks`, start — the qcow2 guest should come back with both drives.

## Still open, unchanged

`sshd` is disabled, so gaming mode has no recovery channel: the host has no
keyboard while the guest runs, and a hung guest means the reset button. This
matters more now than it did, because the guest is writing the real install.
Offered several times, declined.
