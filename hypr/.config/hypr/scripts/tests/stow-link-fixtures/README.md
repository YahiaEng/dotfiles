# stow-link-check fixtures

Six committed `$HOME`-mirror subtrees, each pointed at via `stow-link-check
--root <fixture-dir>` exactly as if it were the real `$HOME`. Every fixture
is a one-artifact mutation of `compliant-resolving-links`, never a
structurally different tree — this is the expected-verdict contract
`stow-link-check --self-test` encodes and replays.

| Fixture | Expected exit | Claim it proves |
|---|---|---|
| `compliant-resolving-links` | 0 | Every stow-created symlink under the declared sweep roots (`.config/hypr/`, `.config/systemd/user/`, `Pictures/Wallpapers/`) resolves; the baseline every poisoned fixture below is a one-artifact mutation of. |
| `poisoned-dangling-config-link` | 1 | The ordinary `~/.config/<pkg>/` case is swept — the `.config/hypr/` link's target is absent, all other links resolve. |
| `poisoned-dangling-systemd-unit` | 1 | The third documented `stow.sh` exception root (`~/.config/systemd/user/`) is swept — a `$HOME/.config`-only sweep would still happen to cover this one, but it must be proven, not assumed. |
| `poisoned-dangling-pictures-link` | 1 | A root OUTSIDE `.config`/`.local` entirely (`~/Pictures/Wallpapers/`) is swept — the case a `$HOME/.config`-only sweep would miss. |
| `poisoned-symlink-chain` | 1 | Full-chain resolution, not a one-hop existence test: `.config/hypr/link-a` points at `.config/hypr/link-b`, an existing directory entry (itself a symlink), whose own target is absent. `readlink` on `link-a` returns a path that exists as a directory entry; `readlink -e` on `link-a` still fails. A shallow one-hop test would call this clean. |
| `empty-no-roots` | 1 | The vacuous-green guard: a fixture root containing none of the declared sweep roots (no `.config`, `.local` or `Pictures`) must FAIL, never PASS, so an empty or absent target tree can never produce a vacuous green. |
