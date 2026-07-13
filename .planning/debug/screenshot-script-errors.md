---
status: diagnosed
trigger: "UAT Test 2 (06-themed-surfaces-utility-suite): screenshot scripts save to ~ instead of ~/Pictures/screenshots; terminal run prints 'getopt: option requires an argument -- r' and 'Error: Unrecognized image file format' (twice)"
created: 2026-07-13T00:00:00Z
updated: 2026-07-13T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED — hyprshot's getopt optstring declares `r:` (argument required) while the handler treats `-r|--raw` as a boolean flag; scripts pass short `-r` as the final arg, getopt fails and drops it, hyprshot silently proceeds in NON-raw mode (exit code masked by `local options=$(getopt ...)`), saves the PNG itself to `~` (xdg-user-dirs not installed → SAVEDIR fallback is `~`), emits nothing on stdout, and satty prints "Error: Unrecognized image file format" twice on empty stdin
test: complete — reproduced every symptom with safe non-capture invocations
expecting: n/a
next_action: return ROOT CAUSE FOUND to orchestrator (goal: find_root_cause_only — no fix applied)

reasoning_checkpoint:
  hypothesis: "hyprshot 1.3.0 optstring bug (`r:` instead of `r`) breaks short `-r`; scripts use `-r`, so raw mode never engages — one root cause producing all three symptoms"
  confirming_evidence:
    - "getopt -o hf:o:m:dszr:t: ... -- -m region -z -r → prints exact user error, exit 1, output ' -m region -z --' (-r dropped)"
    - "Same getopt with --raw → exit 0, '--raw' preserved"
    - "printf '' | satty --filename - ... → prints 'Error: Unrecognized image file format' exactly twice, exit 1 (matches user report verbatim)"
    - "/usr/bin/hyprshot line 303: SAVEDIR=${XDG_PICTURES_DIR:=~}; xdg-user-dirs not installed on this machine → SAVEDIR=~ → PNG lands in home dir"
  falsification_test: "If --raw also failed getopt, or satty printed the error once, or hyprshot's non-raw SAVEDIR were not ~, the single-root-cause chain would break — none of these hold"
  fix_rationale: "Switching scripts from -r to --raw makes getopt succeed and RAW=1 engage; hyprshot then writes raw image to stdout and returns before its own save/notify path, so satty owns save (--output-filename) and the ~ mis-save disappears with the same change"
  blind_spots: "Did not run a live capture (per instructions, no GUI/screenshot); the grim→stdout→satty happy path with --raw is verified by code reading of save_geometry(), not execution"

## Symptoms

expected: Screenshot scripts save captures into ~/Pictures/screenshots and run without errors, opening satty with the frozen screenshot
actual: Screenshots save to the home directory (~) instead of ~/Pictures/screenshots; running the scripts in a terminal prints errors
errors: |
  getopt: option requires an argument -- 'r'
  Error: Unrecognized image file format
  Error: Unrecognized image file format
reproduction: Run any of hypr/.config/hypr/scripts/capture-{full,region,window}.sh from a terminal with hyprshot 1.3.0-4 + satty 0.21.1-1 installed (Arch extra)
started: First run on a machine with the tools actually installed (scripts written in phase 06, never previously exercised live)

## Eliminated

- hypothesis: "satty flags are wrong (--filename - / --output-filename misuse)"
  evidence: "satty --help confirms both flags exist with exactly the semantics the scripts use; satty errors only because stdin is empty, which is downstream of the hyprshot failure"
  timestamp: 2026-07-13

- hypothesis: "the two error messages come from two different consumers"
  evidence: "Reproduced: satty 0.21.1 itself prints 'Error: Unrecognized image file format' exactly TWICE on empty/invalid stdin (verified with printf '' | satty --filename - ...), matching the user report from a single run"
  timestamp: 2026-07-13

- hypothesis: "wrong save dir is an independent bug in the scripts' SCREENSHOT_DIR handling"
  evidence: "Scripts correctly mkdir -p and pass $HOME/Pictures/Screenshots to satty --output-filename; the file in ~ is written by HYPRSHOT (non-raw fallback path grim -g geom \"$SAVE_FULLPATH\" with SAVEDIR=~), not by satty or the script — same root cause as the getopt error"
  timestamp: 2026-07-13

## Evidence

- timestamp: 2026-07-13
  checked: "hypr/.config/hypr/scripts/capture-{region,full,window}.sh (all three, fully)"
  found: "All three pipe `hyprshot -m <mode> -z -r | satty --filename - --output-filename \"$FILENAME\" --disable-notifications` with FILENAME under $HOME/Pictures/Screenshots. `-r` is always the LAST argument. Header comments state -r was 'verified against the live upstream script (github main)'."
  implication: "The -r flag is the load-bearing piece: it must make hyprshot stream raw image data to stdout instead of saving itself"

- timestamp: 2026-07-13
  checked: "Installed hyprshot 1.3.0-4 (/usr/bin/hyprshot, a bash script) — getopt invocation, line 235"
  found: "optstring is `hf:o:m:dszr:t:` — `r:` declares short -r as REQUIRING an argument, but the long option list has `raw` (no colon) and the case handler is `-r | --raw) RAW=1` (boolean, no shift). Upstream main branch has the identical `r:` bug (fetched raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot line 239)."
  implication: "Short -r is broken in hyprshot itself (upstream bug); only the long form --raw works. The dev-time 'verification' read the case handler but missed the optstring"

- timestamp: 2026-07-13
  checked: "Safe reproduction: `getopt -o hf:o:m:dszr:t: --long ...,raw,... -- -m region -z -r`"
  found: "Prints `getopt: option requires an argument -- 'r'` (exact user error), exit 1, and outputs ` -m 'region' -z --` — the -r is DROPPED. With `--raw` instead: exit 0, output ` -m 'region' -z --raw --`."
  implication: "getopt failure is non-fatal to hyprshot (`local options=$(getopt ...)` masks the exit status from `set -e`), so hyprshot proceeds with RAW=0 → normal save mode"

- timestamp: 2026-07-13
  checked: "/usr/bin/hyprshot save path: save_geometry() lines ~108-130, SAVEDIR resolution lines 301-307"
  found: "RAW=1 path: `grim -g geom -` to stdout, returns before save/notify. RAW=0 path: `grim -g geom \"$SAVE_FULLPATH\"` + wl-copy. SAVEDIR: `[ -z \"$XDG_PICTURES_DIR\" ] && type xdg-user-dir && XDG_PICTURES_DIR=$(xdg-user-dir PICTURES)` then `SAVEDIR=${XDG_PICTURES_DIR:=~}`. On this machine `xdg-user-dirs` is NOT installed (pacman -Q fails, command not found) → SAVEDIR=~."
  implication: "With RAW silently off, hyprshot itself saves the screenshot into ~ (home dir) and writes nothing to stdout — explains both the mis-saved file location and satty's empty stdin"

- timestamp: 2026-07-13
  checked: "Safe reproduction: `printf '' | satty --filename - --output-filename <scratch>/test-empty.png --disable-notifications`"
  found: "Prints `Error: Unrecognized image file format` exactly TWICE, exit 1, no GUI"
  implication: "The doubled satty error in the user report is satty 0.21.1's own behavior on empty stdin from a single script run — fully downstream of the -r failure, not a second bug"

- timestamp: 2026-07-13
  checked: "Naming detail: UAT truth says ~/Pictures/screenshots (lowercase), scripts use $HOME/Pictures/Screenshots (capital S)"
  found: "Scripts consistently use 'Screenshots'; UAT wording uses 'screenshots'"
  implication: "Cosmetic wording mismatch only — not the bug, but worth aligning during gap closure so verification text matches the implemented path"

## Resolution

root_cause: "hyprshot 1.3.0 (and upstream main) has a getopt optstring bug: short option string `hf:o:m:dszr:t:` declares `r:` (argument required) while `--raw`/the handler treat it as a boolean flag. All three capture scripts pass short `-r` as the last argument, so util-linux getopt errors ('option requires an argument -- r') and drops -r from the parsed args; hyprshot masks the getopt failure (`local options=$(getopt ...)`) and proceeds with RAW=0. Consequences of this single failure: (1) hyprshot takes the normal save path and writes the PNG itself into SAVEDIR=~ — home dir, because XDG_PICTURES_DIR is unset and xdg-user-dirs is not installed so the fallback `${XDG_PICTURES_DIR:=~}` applies; (2) nothing is written to stdout, so satty receives empty stdin and prints 'Error: Unrecognized image file format' twice (verified satty 0.21.1 double-print behavior); (3) satty exits 1 before opening, so --output-filename never saves to ~/Pictures/Screenshots."
fix: ""
verification: ""
files_changed: []
