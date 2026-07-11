---
status: diagnosed
trigger: "hyprlock-enter-first-input-drop: After lock screen activates, pressing ENTER first (before typing) causes failed authentication and subsequent keystrokes never appear in the password input box. Typing the password immediately (without pressing ENTER first) works fine."
created: 2026-07-11T18:19:10Z
updated: 2026-07-11T18:32:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: CONFIRMED — ENTER on the empty field submits an empty password to PAM (ignore_empty_input defaults to 0 and is not set in this repo's hyprlock.conf); hyprlock 0.9.5 silently DROPS (does not queue) every keystroke while the PAM round is in flight (onKey checkWaiting gate), the failed empty round lasts ~2-3s due to libpam's failure delay, and the input field renders zero feedback during that window (updateDots early-returns while checkWaiting). Password typed in that window vanishes; re-pressing ENTER restarts the loop.
test: Verified against hyprlock 0.9.5 source (exact installed version), journalctl PAM failure timestamps, and the live PAM stack — see Evidence.
expecting: n/a — root cause confirmed with direct source + journal evidence
next_action: Return ROOT CAUSE FOUND diagnosis to orchestrator (goal: find_root_cause_only — no fix applied); plan-phase --gaps handles the fix (set general:ignore_empty_input = true in hypr/.config/hypr/hyprlock.conf)

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: After the lock screen activates, 100% first-try unlock across both the manual-lock keybind and idle-lock (loginctl lock-session) paths — the user types their password in one attempt with no dropped input and no failed-auth loop.
actual: "If I start typing the password immediately, hyprlock works just fine. But if I try to press 'ENTER' key and then type my password, it fails authentication and no characters get typed inside the password input box." (verbatim user report)
errors: None reported
reproduction: Test 2 in UAT (.planning/phases/04-reliability-fixes-tech-debt/04-UAT.md) — lock screen (manual keybind or loginctl lock-session), press ENTER on the empty password field, then type the password
started: Discovered during Phase 04 UAT (2026-07-11), after plan 04-02 fixed FIX-02 (first-keystroke drop) via schema migration + immediate_render + fadeIn disabled in hypr/.config/hypr/hyprlock.conf

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: pam_faillock temporary account lockout (deny=3 default) explains the persistent "fails authentication" behavior
  evidence: journalctl (2026-07-11) has zero "temporarily locked" / "Consecutive login failures" lines; `faillock --user aorus` shows an empty tally (successful unlocks reset it via authsucc); each lock session in the journal shows at most 2-3 failures followed by successful unlock. Faillock is a hardening consideration for the fix (repeated empty submits do count toward deny=3), not the cause.
  timestamp: 2026-07-11T18:27:00Z

- hypothesis: residual FIX-02 lock-surface keyboard-focus race (keys delivered to the previously focused client instead of hyprlock) explains the dropped characters
  evidence: The type-immediately path now works 100% per the user's own report, so the lock surface has keyboard focus; and the ENTER press itself demonstrably reaches hyprlock — journal shows pam_unix(hyprlock:auth) failures ~1 second after "Started hyprlock" (16:17:39→16:17:40, 16:19:45→16:19:46, 19:37:28→19:37:29). The drop happens INSIDE hyprlock's onKey gate after delivery, not before delivery.
  timestamp: 2026-07-11T18:27:00Z

- hypothesis: hyprwm/hyprlock#423 grace-race
  evidence: Already ruled out in 04-02 (grace is CLI-only in 0.9.5, never passed); additionally this symptom triggers on ENTER-first, with grace irrelevant. Confirmed onKey grace path (m_tGraceEnds) can't fire with grace 0.
  timestamp: 2026-07-11T18:27:00Z

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-07-11T18:21:00Z
  checked: pacman -Q hyprlock; hyprlock --version; repo hyprlock.conf; deployed ~/.config/hypr/hyprlock.conf
  found: hyprlock 0.9.5-4 installed. Neither the repo config (hypr/.config/hypr/hyprlock.conf) nor the deployed config sets `general:ignore_empty_input`.
  implication: The empty-input guard is at its default. Whatever the default is, it governs what ENTER on an empty field does.

- timestamp: 2026-07-11T18:24:00Z
  checked: journalctl --since 2026-07-11, grep hyprlock|pam_unix
  found: Repeated `pam_unix(hyprlock:auth): authentication failure` entries logged ~1 second after `Started hyprlock` scope creation (16:17:39→16:17:40, 16:19:45→16:19:46, 19:37:28→19:37:29, and a 20:53:55–20:54:39 cluster of rapid lock/unlock trials with 3 failures — the UAT reproduction). Also two consecutive failures 3 seconds apart at 15:17:20/15:17:23 (the 04-02 Task 2 checkpoint repro).
  implication: An auth round demonstrably starts ~1s after lock — a submitted (empty) password immediately after locking. The 3s gap between consecutive failures matches a ~2s PAM failure delay plus retype/resubmit. The ENTER keypress IS delivered to hyprlock.

- timestamp: 2026-07-11T18:25:00Z
  checked: /etc/pam.d/hyprlock → system-local-login → system-login → system-auth; /etc/security/faillock.conf; faillock --user aorus
  found: hyprlock's PAM stack includes pam_unix (`try_first_pass nullok`, NO `nodelay`) and pam_faillock (preauth/authfail/authsucc, all-default config → deny=3, unlock_time=600). Faillock tally currently empty.
  implication: pam_unix requests its default ~2s failure delay (pam_fail_delay(2000000)) on every failed auth, applied by libpam inside pam_authenticate before it returns. Every empty-password submit costs a ~2s blocked round. Repeated empty submits also count toward faillock's deny=3 (10-min lockout) — a real hardening concern, though it did not trigger during UAT.

- timestamp: 2026-07-11T18:28:00Z
  checked: hyprlock v0.9.5 source (tag v0.9.5, matches installed binary) — src/core/hyprlock.cpp onKey/handleKeySym
  found: onKey lines 617-620 — `if (g_pAuth->checkWaiting()) { renderAllOutputs(); return; }` — every key event is silently DISCARDED (not queued) while an auth round is in flight. handleKeySym lines 656-666 — ENTER submits the buffer; the empty-buffer early-return at 661-664 only fires when `general:ignore_empty_input` is enabled. ConfigManager.cpp:240 — `ignore_empty_input` defaults to `Hyprlang::INT{0}` (off).
  implication: With the repo config at default, ENTER on an empty field submits "" to PAM, and every keystroke typed while that round is in flight is dropped on the floor.

- timestamp: 2026-07-11T18:29:00Z
  checked: hyprlock v0.9.5 src/auth/Pam.cpp (thread loop, waitForInput, handleInput, checkWaiting) and src/auth/Pam.hpp
  found: `checkWaiting()` = `m_bBlockInput || waitingForPamAuth` (Pam.cpp:175-177). `handleInput` sets waitingForPamAuth=true at submit; the woken PAM thread sets m_bBlockInput=true (waitForInput exit, line 152) and only clears it when it loops back into `waitForInput()` AFTER `pam_authenticate` returns, `enqueueFail` runs, and the conversation resets (init loop lines 82-107, m_bBlockInput=false at line 148). pam_authenticate's return is delayed ~2s by libpam on failure.
  implication: The input-blocked window spans submit → PAM verify → ~2s fail delay → fail enqueue → next prompt. For an empty-password submit that is ~2-3s of total keyboard deafness — precisely when the user is typing their real password.

- timestamp: 2026-07-11T18:30:00Z
  checked: hyprlock v0.9.5 src/renderer/widgets/PasswordInputField.cpp updateDots/updateFade/draw
  found: updateDots lines 167-168 — `if (checkWaiting && configCheckText.empty()) return;` — dot count is frozen during the in-flight round when no check text is configured (this repo configures none). Keys are dropped before reaching the buffer anyway (onKey gate), so passwordLength stays 0.
  implication: During the blocked window the field shows no dots, no motion, no cue — matching the verbatim report "no characters get typed inside the password input box." The only subtle cue is check_color on the field border, easy to miss.

- timestamp: 2026-07-11T18:31:00Z
  checked: End-to-end mechanism reconstruction against both reproduction paths
  found: Type-immediately path — PAM thread is parked in waitForInput (m_bBlockInput=false, no round in flight), keys buffer normally, ENTER submits the full password → success, matching "works just fine." ENTER-first path — empty submit starts a ~2-3s blocked round; a full password typed at normal speed falls entirely (or mostly) inside that window and is discarded; the next ENTER submits empty/partial → second failure → new blocked window → perceived failed-auth loop.
  implication: One mechanism explains both the working and failing paths plus the journal timestamps. Root cause confirmed.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  hyprlock 0.9.5 silently discards — it does not queue — all keyboard input while a PAM
  verification is in flight (`CHyprlock::onKey` early-returns when `g_pAuth->checkWaiting()`
  is true; src/core/hyprlock.cpp:617-620). Pressing ENTER on the empty password field starts
  exactly such a verification, because `general:ignore_empty_input` defaults to 0 and is not
  set in hypr/.config/hypr/hyprlock.conf — the empty string is submitted to PAM
  (handleKeySym, hyprlock.cpp:656-666; default at ConfigManager.cpp:240). The empty-password
  round fails in pam_unix and libpam applies its ~2s failure delay inside pam_authenticate
  (pam stack: hyprlock → system-local-login → system-login → system-auth, pam_unix without
  `nodelay`; journal shows consecutive hyprlock:auth failures 3s apart). Input stays blocked
  from submit until the PAM thread finishes pam_authenticate, enqueues the failure, and
  re-enters waitForInput (`m_bBlockInput` true across the whole window; Pam.cpp:146-153,
  175-177). Every character of the password typed during that ~2-3s window is silently
  dropped, and the input field gives no feedback — updateDots early-returns during
  checkWaiting when no check text is configured (PasswordInputField.cpp:167-168). Any
  subsequent ENTER re-submits an empty or truncated password and restarts the blocked
  window, producing the reported "fails authentication and no characters get typed" loop.
fix: ""  # not applied — goal is find_root_cause_only; suggested direction: set `ignore_empty_input = true` in the general{} block of hypr/.config/hypr/hyprlock.conf (upstream option built for exactly this scenario: ENTER on an empty buffer is ignored, no PAM round, no blocked window, no faillock tally growth)
verification: ""  # pending fix; re-run UAT Test 2 (ENTER first, then type) on both manual-lock and loginctl lock-session paths
files_changed: []
