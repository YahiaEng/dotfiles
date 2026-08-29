# Single-GPU VFIO passthrough — Windows 11 gaming VM

Built in quick task `260829-vfi`. This document exists because **the whole
VFIO half of that task is untestable from the machine that wrote it** — there
is no `/dev/kvm` on this host until a firmware setting changes, so nothing
below has been exercised. Everything here is either a measured fact about the
hardware or a step you have to run. Where a claim is unverified, it says so.

---

## Read this first: what this VM is and is not for

**League of Legends will not run in it.** Riot's Vanguard anti-cheat blocks
Wine, Proton and every virtual machine as of patch 26.8 (2026). This is the
anti-cheat's stated design, not a configuration gap, and no amount of hiding
the hypervisor changes it — the `<kvm><hidden/>` and `vendor_id` settings in
the domain XML defeat a *driver* check from 2020, not a kernel anti-cheat.

**You already have the only thing that runs LoL on this machine.**
`/boot/limine.conf` carries a `/Windows` entry pointing at
`EFI/Microsoft/Boot/bootmgfw.efi`, and Windows 11 is installed on `nvme1n1p3`
(641.9 GB NTFS, with its ESP on `p1` and recovery on `p4`). Reboot, pick
Windows at the limine menu. That is the supported path and it works today.

This VM is for **Windows-only games with no kernel anti-cheat**, run without
rebooting. For everything that *does* work under Proton — which on an RTX 3070
is the large majority of the Windows catalogue — the native stack is faster and
far less trouble. Use `gamerun` (see the bottom of this file) first, and reach
for this VM only when a title genuinely refuses.

---

## Why this is a *single-GPU* setup, and what that costs you

The Ryzen 5 5600X has **no integrated graphics**. `lspci` reports exactly one
display adapter: the RTX 3070 at `07:00.0`. So there is no second GPU to keep
the host alive while the first is handed to a guest.

The consequence is unavoidable and worth being clear-eyed about:

> **Starting the VM tears down your desktop.** SDDM stops, Hyprland exits,
> every open application dies with it, and the monitor switches to the guest.
> Stopping the VM brings the login screen back. This is a full mode switch,
> not a window you alt-tab out of.

If that is not acceptable, do not use this VM — reboot into the bare-metal
Windows install instead, which costs about the same and runs anti-cheat games
too.

### The one line you must never add

Every VFIO tutorial tells you to pin the card at boot:

```
# /etc/modprobe.d/vfio.conf
options vfio-pci ids=10de:2484,10de:228b     # <-- NEVER ON THIS HOST
```

On a two-GPU machine that is correct. Here it binds your **only** display
adapter to `vfio-pci` before userspace starts, and the machine boots to a
black screen with no framebuffer, no SDDM and no Hyprland — recoverable only
over SSH or from another computer. The shipped `vfio.conf` carries module
*ordering* only, and `install.sh` repeats this warning at the install site.
Binding happens late, from the libvirt hook, once the desktop is already down.

---

## The hardware, as measured

IOMMU is already active (22 groups) with no kernel parameter needed — AMD-Vi
is on by default on this board once virtualisation is enabled.

| Group | Device | Role in this setup |
|---|---|---|
| **16** | `07:00.0` RTX 3070 + `07:00.1` its HDMI audio | passed as one multifunction device |
| **20** | `09:00.3` CPU USB controller | passed — carries **keyboard, mouse and a USB audio device** |
| **21** | `09:00.4` onboard HD audio | passed — the analog jack, currently the host default sink |
| 15 | chipset USB, SATA, both NVMe, Ethernet, WiFi | **never touch** — one tangled group |

Group 20 is the reason this configuration has no mouse problem and no sound
problem. Because all three input/audio devices sit on one cleanly-isolated
controller, passing that single device gives the guest native USB input and
native audio. There is no evdev bridging, no pointer-capture hotkey, no
Scream, and no PulseAudio tunnel — the four things that make most passthrough
guides miserable to follow.

Host recovery is preserved: the *other* USB controller (`02:00.0`, buses
001/002) stays with the host and has input devices on it, so a failed teardown
does not leave the machine without a keyboard.

---

## Operator checklist

Steps 1–2 are **blocking** — nothing else can be attempted until they are
done. Steps marked **[UNVERIFIED]** could not be exercised from the session
that wrote them and are the ones to watch.

### 1. Enable AMD-V in firmware — BLOCKING

Measured on this host right now:

```
$ grep -w svm /proc/cpuinfo   ->  (no output — the flag is absent)
$ ls /dev/kvm                 ->  No such file or directory
```

Virtualisation is switched **off** in UEFI. Without it, QEMU silently falls
back to TCG software emulation, and a Windows guest under TCG is far too slow
to be worth booting.

1. Reboot, enter UEFI setup.
2. **Advanced → CPU Configuration → SVM Mode → Enabled.**
3. Save and exit.

Confirm afterwards:

```bash
grep -w svm /proc/cpuinfo   # must print a flags line
ls -l /dev/kvm              # must exist
```

If `/dev/kvm` exists but is not group-accessible, add yourself:
`sudo usermod -aG kvm,libvirt "$USER"` and log out and in.

### 2. Install and start the stack

One command. `install.sh --gaming-only` runs just this section — the packages,
the sysctl and NVIDIA module tuning, the VFIO hooks, the initramfs rebuild,
and libvirtd with its default network — without re-walking a full install
(which on this host would rebuild the AUR packages; `tela-icon-theme` alone
measures 21 minutes).

```bash
./install.sh --gaming-only
```

It prompts for sudo once and keeps the credential alive for its own calls.

Two things it does that are easy to miss if you install by hand:

- **`mkinitcpio -P`.** modprobe.d options are read *when the module loads*,
  and nvidia is pulled into the initramfs here by mkinitcpio's autodetect even
  though `MODULES=()` is empty. So nvidia loads early and reads the
  *initramfs's* copy of `/etc/modprobe.d` — without the rebuild,
  `nvidia-gaming.conf` is inert and the tuning silently does nothing.
- **`virsh net-start default`.** Installing libvirt does not start its NAT
  network, and a guest on an inactive network has no connectivity with no
  obvious cause. This is the most common "the VM has no internet" report.

Confirm the tuning actually reached the module:

```bash
modprobe --dry-run --show-depends nvidia | grep NVreg_Initialize
# -> ... nvidia.ko.zst ... NVreg_InitializeSystemMemoryAllocations=0 ...
```

### 3. Storage pool, disk and ISOs

**Do this through libvirt, not through sudo.** Membership of the `libvirt`
group (already granted here) gives unprivileged access to the *system* daemon
at `qemu:///system`, and libvirtd runs as root — so it performs the privileged
writes into `/var/lib/libvirt/images` on your behalf. No `sudo` is needed for
any of this section.

Two traps this avoids:

- `/var/lib/libvirt/images` is `root:root 755`, so you cannot write there
  directly however you got the file.
- Keeping images in your home instead does not work: `/home/aorus` is `750`,
  and qemu runs as **`libvirt-qemu`** (uid 954), which cannot traverse it. The
  VM fails to start with a permission error that points at the image rather
  than at the directory above it.

```bash
export LIBVIRT_DEFAULT_URI=qemu:///system

# One-time: the default pool does not exist on a fresh libvirt install.
virsh pool-define-as default dir --target /var/lib/libvirt/images
virsh pool-build default && virsh pool-start default && virsh pool-autostart default

# Guest system disk. NOTE: no --prealloc-metadata. That flag fully allocates
# on ext4 and consumed the whole 200 GiB up front when this was first run;
# without it the image starts at ~196 KiB and grows as used.
virsh vol-create-as default win11-gaming.qcow2 200G --format qcow2
```

Importing an ISO you have downloaded (the same two commands work for either
ISO — create a volume of the right size, then stream the file into it):

```bash
SRC=~/Downloads/Win11.iso                 # wherever you saved it
SIZE=$(stat -c%s "$SRC")
virsh vol-create-as default Win11.iso "$SIZE" --format raw
virsh vol-upload --pool default Win11.iso "$SRC"
virsh vol-list default --details          # confirm
```

#### The virtio-win ISO is not optional

The Windows installer cannot see a virtio disk without loading a driver from
it, and presents "no drives found" with no hint as to why. It comes from
Red Hat and has a stable URL, so it can be fetched directly:

```bash
curl -L -o ~/vm-staging/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

#### The Windows 11 ISO needs a browser

Microsoft's download API **cannot be scripted**. The session flow can be
walked as far as the SKU list, but the final link request returns:

```
{"Errors":[{"Key":"ErrorSettings.SentinelReject",
            "Value":"Sentinel marked this request as rejected."}]}
```

That is deliberate anti-automation on Microsoft's side, not a broken request —
the same call succeeds from a browser. So fetch it by hand:

1. Open <https://www.microsoft.com/software-download/windows11>
2. Under **Download Windows 11 Disk Image (ISO)**, pick *Windows 11 (multi-edition ISO)*
3. Choose your language, then **64-bit Download** (the link is valid 24 hours)
4. Import it with the `vol-create-as` / `vol-upload` pair above

### 4. Define the domain

```bash
sudo virsh define ~/dotfiles/vfio/win11-gaming.xml
```

The domain name `win11-gaming` is matched literally by
`/etc/libvirt/hooks/qemu`. **Renaming the domain without editing the hook
silently disables passthrough** and the guest boots with no GPU.

### 5. Install Windows — in INSTALL MODE, windowed

**Do not install in passthrough mode.** Windows Setup needs a keyboard, and
this host cannot pass one through a PCI group: the only real keyboard is the
Corsair K70 (`1b1c:1b73`) on the chipset USB controller `02:00.0`, which shares
IOMMU group 15 with both NVMe drives, SATA, Ethernet and WiFi. That group can
never be passed.

So installation runs in a **windowed VM with no passthrough at all** — an
emulated display and keyboard, shown on your running desktop. Nothing is torn
down, and you can read these notes while it installs.

```bash
virsh define ~/dotfiles/vfio/win11-install.xml   # same domain, no passthrough
virsh start win11-gaming
virt-manager                                     # double-click the domain to view
```

Both XML files carry the **same name and UUID**, so `virsh define` switches the
existing domain between shapes rather than creating a second one. Only one
definition is active at a time, so the two can never both claim the disk.

At the disk step, "Load driver" → the virtio-win ISO → `viostor`, then `NetKVM`
for networking. Without that, Setup shows "no drives found" and does not say why.

Install the rest of the virtio guest tools from the same ISO before shutting
down. Then, and only then, switch to passthrough:

```bash
virsh shutdown win11-gaming
virsh define ~/dotfiles/vfio/win11-gaming.xml    # back to passthrough
```

> **Unlink any host drive before installing.** Windows Setup places its boot
> files on `Disk 0` regardless of which disk you install *to*, so a linked data
> drive can end up with a System Reserved partition written onto it. Toggle
> drives off in Settings → Virtualization, install, then toggle them back on.

### 6. Verify the teardown/restore cycle — **[UNVERIFIED, highest risk]**

This is the step that can cost you your display. Do it when you can afford a
hard reboot, and ideally with SSH access from another machine open first.

```bash
# from a TTY or over SSH, not from a terminal inside Hyprland
sudo virsh start win11-gaming
# ... desktop goes down, guest takes the monitor ...
sudo virsh shutdown win11-gaming
# ... SDDM should return within ~15s ...
```

Then read the log the hooks write at every step:

```bash
sudo cat /var/log/vfio-hook.log
```

The restore script is deliberately written to be forgiving: it is **not**
`set -e`, and `systemctl start sddm` runs unconditionally at the end no matter
what failed above it. A half-restored driver with a running display manager is
recoverable; an early exit that never restarted SDDM is not.

**If the screen stays black after shutdown:** switch to a TTY with
Ctrl+Alt+F2 and run `sudo systemctl start sddm`. If there is no TTY either,
SSH in. If neither works, hard reboot — nothing here persists across a reboot
except the module ordering file, which is inert on its own.

### 7. Guest-side tuning — **[UNVERIFIED]**

Inside Windows: install the NVIDIA driver normally, set the power mode to
"Prefer maximum performance", and disable "Memory Integrity"
(Core Isolation) — it is a nested-virtualisation feature that costs real
frames inside an already-virtualised guest.

---

## Deliberate design choices you might otherwise "fix"

| Choice | Why |
|---|---|
| 8 vCPUs, not 12 | Cores 0 and 1 are held back for the host, the QEMU emulator thread and the iothread. Give the guest all 6 cores and the emulator competes with the vCPUs it serves — frametimes get *worse*. |
| Pinning pairs `n`/`n+6` | Read from `thread_siblings_list` on this host, not assumed. Each guest "core" lands on a real SMT sibling pair, so the guest scheduler's decisions match physical topology. |
| Transparent hugepages, not static | Static hugepages are reserved from the host permanently, including while the VM is off. On a desktop that is a bad trade. See below to opt in. |
| `cache='none'` + `io='native'` | `io=native` *requires* `cache=none`; pairing them wrongly silently falls back to a slower path. |
| No `<graphics>`, `<video>` or `<sound>` | The passed-through GPU drives the real monitor. An emulated adapter would become Windows' primary display and leave the real screen blank. |
| GPU + its audio on one guest slot | Mirrors the host layout (`07:00.0`/`.1`). NVIDIA's driver expects its audio function beside the card; splitting them is a known cause of the guest audio function failing to bind. |
| `release/end`, not `stopped/end` | `stopped` fires while libvirt still holds the device; rebinding nvidia there races teardown and intermittently leaves the card half-claimed. |

### Optional upgrades, both opt-in

**Static hugepages** — a few percent, at the cost of 16 GB reserved from the
host at all times. Add `default_hugepagesz=1G hugepagesz=1G hugepages=16` to
the limine cmdline and swap the `<memoryBacking>` block for `<hugepages/>`.

**Raw-passthrough of the existing Windows install** — the fastest storage
option, and it would give you *one* Windows bootable both bare-metal and as a
VM. **Not built, and not recommended without thought.** Booting the same
install two ways changes the hardware hash Windows activation keys on, and
Fast Startup leaves the NTFS in a hibernated state that Linux must never mount
concurrently. If you want it: disable Fast Startup in Windows first, confirm
`nvme1n1` is unmounted on the host, and replace the `<disk>` block with a
`<disk type='block'>` pointing at `/dev/nvme1n1`. Ask before doing this — it
is the one change here that can damage an existing installation.

---

## The native stack, which you should try first

Installed by the same quick task and testable today, no BIOS change required.

```bash
gamerun <command>                       # tuned env + gamemode + MangoHud
gamerun --gamescope 2560x1440 <cmd>     # under gamescope
gamerun --fsr <cmd>                     # FSR upscaling
gamerun --hud <cmd>                     # HUD visible from the start
```

Steam launch options: `gamerun %command%`

MangoHud starts hidden; **Right-Shift + F12** toggles it, **Left-Shift + F2**
toggles logging.

The wrapper sets the shader-cache, NVAPI/DLSS and VKD3D raytracing variables
at the game process rather than session-wide, deliberately — session-wide they
would also reach Hyprland, Quickshell and every GTK app, where a 12 GiB shader
cache with cleanup disabled is pure cost. See `gaming/.local/bin/gamerun`,
where each variable carries the reason it is set.
