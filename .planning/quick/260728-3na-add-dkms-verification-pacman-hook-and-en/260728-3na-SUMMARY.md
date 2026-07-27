---
id: 260728-3na
title: DKMS verification pacman hook + kernel-modules-hook reaper
status: complete
date: 2026-07-28
commits:
  - 745ad22
  - 1868826
---

# Quick Task 260728-3na — Summary

## What shipped

| File | Change |
|---|---|
| `system/usr/local/bin/dkms-verify` | New. Cross-checks installed kernels against registered DKMS modules. |
| `system/etc/pacman.d/hooks/99-dkms-verify.hook` | New. PostTransaction hook, sorts after `70-dkms-install`. |
| `install.sh` | `REPO_DIR` added; `section_hardware()` places both files and enables `linux-modules-cleanup.service`. |

## Two design decisions that carry the fix

**Kernels are enumerated by `pkgbase`, not by directory glob.** Upstream's
`all_kver()` globs `/usr/lib/modules/*/build/`, which is why 13 orphaned trees left
by `kernel-modules-hook` inflated its build list from 1 kernel to 14. Only real,
package-owned kernel trees carry a `pkgbase` marker, so orphans are structurally
invisible to this check.

**Detection matches `dkms status` output text, never its exit status.** Verified on
dkms 3.4.1: `dkms status -m nvidia -v 610.43.03 -k <never-built-kernel>` **exits 0**
and prints `nvidia/610.43.03: added`. An exit-code check would have passed silently
and reproduced the exact bug being guarded against. The script requires a line
matching `^<name>/<ver>, <kver>, .*: installed` — the kernel field is what separates
"source registered" from "modules on disk".

Secondary: `dkms.conf` is parsed with `sed` rather than sourced, because those files
contain command substitution (nvidia's `MAKE[0]` runs `` `nproc` ``) and a root
PostTransaction hook should not execute them to read two strings.
`BUILD_EXCLUSIVE_KERNEL` is honoured as upstream does, so a module that legitimately
excludes a kernel is not reported missing.

## Verification performed

| Test | Result |
|---|---|
| `bash -n` on both scripts | pass |
| `shellcheck -S warning` on both | clean, exit 0 |
| Real current state (7.1.5-arch1-1 + nvidia/610.43.03) | `OK — 1 pair verified`, exit 0 |
| Synthetic missing kernel 9.9.9 alongside good 7.1.5 | exit 1; flagged **only** 9.9.9, emitted correct `dkms install` remedy |
| 1 real kernel + 2 orphan trees **with headers** (incident's exact shape) | exit 0 — orphans ignored, confirming the `pkgbase` property |
| `REPO_DIR` resolution from a foreign cwd | resolves correctly |
| Git file mode | `100755` recorded for the script |

## Not done in this task

- **Not yet installed on the live machine.** The repo is correct and a fresh
  `install.sh` run is covered, but `/usr/local/bin/dkms-verify` and
  `/etc/pacman.d/hooks/99-dkms-verify.hook` still need placing on this host — both
  require root.
- **Not yet re-verified against a second kernel.** `linux-lts` was not installed at
  the time of writing. The multi-kernel path is covered by the synthetic test but
  should be re-run once LTS lands.
- **`NVIDIA_PKGS` lists `nvidia-dkms`** (proprietary) while this machine runs
  `nvidia-open-dkms`. A real discrepancy — a fresh install would produce a different
  driver than the one in use. Out of scope here; worth its own task.
