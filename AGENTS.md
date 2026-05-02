# AGENTS.md

This file provides guidance to agents (Claude Code and Codex) when working with code in this repository. It is the canonical source of shared instructions for code agents.

## Canonical Source for Agent Instructions

Shared instructions for code agents (Claude Code and Codex) live **only in this file** (`AGENTS.md`). `CLAUDE.md` is a short wrapper that imports this content via `@AGENTS.md` for Claude Code — avoids duplication and divergence.

Editing convention:

- **Shared instructions** (architecture, contracts, conventions, preferences, patterns) → edit `AGENTS.md`. Both Claude Code and Codex pick up the change automatically.
- **Claude Code-specific instructions** (hooks, slash commands, agent SDK, UI-specific nuances) → add them in `CLAUDE.md`, below the `@AGENTS.md` import, without interfering with Codex.
- **Codex-specific instructions** → Codex doesn't currently support `@file` imports, so they would go directly in `AGENTS.md` (or in a parallel wrapper if needed).

Practical implication: when asked to "update CLAUDE.md", the real destination is `AGENTS.md` unless the change is Claude-specific.

## Overview

Personal zsh configuration for macOS. The repo lives in `~/.dotfiles` and is activated with two symlinks from `$HOME`:

```zsh
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.zshenv ~/.zshenv
```

New machine installation: `cd ~/.dotfiles && ./install.sh && source ~/.zshrc`. Detailed flow from scratch in [docs/setup.md](docs/setup.md).

**Always use `./test.sh`** to validate working tree changes, never `zsh -i -c exit`: the latter loads the installed `~/.zshrc` (possibly symlinked to another clone), not the current tree. `test.sh` sources modules directly. All eight checks and their limits are documented in [docs/reference.md](docs/reference.md).

## Commands

| Command | Purpose |
|---|---|
| `./test.sh` | Complete smoke test (eight checks) |
| `zsh -n <file>` | Verify syntax of a file |
| `ZPROF=true zsh -i -c exit` | Measure startup times |
| `./install.sh` | Create/update symlinks |
| `brew bundle --file=Brewfile` | Install declared dependencies |
| `DOTFILES=/path/clone zsh -i` | Point `.zshrc` to an alternate clone (ergonomics, doesn't substitute `./test.sh`) |

## Architecture

`.zshrc` loads in order: main modules → functions → shell options → plugins. Order matters.

**Main modules** (explicitly loaded from `zsh/` in this order):

1. `exports.zsh` — environment variables and compilation flags
2. `path.zsh` — `$PATH` in precedence order (static entries derived from `exports.zsh` variables)
3. `tools.zsh` — tools (Homebrew, rbenv lazy, nvm lazy, pyenv cached, Starship, Swiftly, Kitty)
4. `node.zsh` — nvm default version, exports `NVM_CURRENT_NODE_VERSION`, injects node bin into `$PATH` (requires `HOMEBREW_PREFIX` from `tools.zsh`)
5. `aliases.zsh` — aliases by domain
6. `completions.zsh` — `fpath`, `compinit`, cached completions

**Functions** (`zsh/functions/*.zsh`, loaded by glob — order doesn't matter): `general`, `git`, `docker`, `ios`, `flutter`, `postgres`, `ssh`.

**Support helpers** (not shell runtime):

- `scripts/check-brewfile.sh` — non-destructive Brewfile diagnostics (host vs repo).
- `scripts/check-docs-drift.sh` — anti-drift implementation ↔ `docs/reference.md`.
- `scripts/check-install.sh` — behavioral validation of `install.sh` in a sandbox.
- `scripts/check-runtime-symbols.sh` — validates that documented symbols exist after module loading.

**Order invariants (don't change):**

- `exports.zsh` before `path.zsh` (latter uses `$FLUTTER_SDK_ROOT`, `$ANDROID_SDK_ROOT`, `$SWIFTLY_HOME`, `$OPENSSL_PATH`, `$PYENV_ROOT`).
- `node.zsh` always after `tools.zsh` (needs `HOMEBREW_PREFIX` from cached `brew shellenv`).
- `node.zsh` always before `aliases.zsh` and `completions.zsh` (PATH must be complete before completions query it).
- `zsh-syntax-highlighting` always at end of `.zshrc` (modifies zle hooks).
- `typeset -U PATH path fpath` before module loop (avoids duplicates on reload).
- `SHELL_SESSIONS_DISABLE=1` goes in `.zshenv`, not `.zshrc` (the `/etc/zshrc_Apple_Terminal` helper runs between them; in `.zshrc` it's too late).
- `HIST_FCNTL_LOCK` always together with `SHARE_HISTORY` (prevents history corruption).

## Security

Host security is a first-level constraint:

- No `curl | sh`, remote `source`, dynamic `eval` or automatic third-party script loading without explicit justification.
- Any integration that executes code, loads completions or writes caches must be conditional, auditable and easy to disable.
- Prefer conservative defaults over opaque "convenience features".
- Tests must fail if the repo starts depending on unsafe host side effects.

### Acceptance Gate for New Integrations

No change is considered closed if it:

- Introduces new implicit execution (`eval`, `source`, hook, cache writer, dynamic generation) without explicit justification **and** specific validation covering it.
- Doesn't make clear how to disable or isolate it in case of trouble.
- Increases trust in external binaries or depends on non-auditable host side effects.
- Would make a test that currently detects an unsafe dependency stop signaling it: tests must **fail**, not silence, if unsafe dependencies are introduced.

Practical application: any improvement requiring `eval`, `source`, new hooks, cache writers or dynamic generation must be **justified, delimited and covered by validation** before considering it merged.

## Design Principles and Tradeoffs

When a change must choose between two properties, priority is closed:

- **Detectability > Portability**: if extra isolation for portability degrades smoke test signal about real load errors, portability is sacrificed.
- **Operational Simplicity > Flexibility**: if an improvement adds modes, flags or combinations to `test.sh`/`install.sh`, strong justification is needed; default is to discard for a single path. `SKIP_BREWFILE` is the only current exception.
- **Load Origin Clarity > Convenience**: when in doubt about which clone or `.zshrc` starts the shell, explicit stable warning is preferred over "smart" resolution or auto-detection.
- **Warning + Fallback > Fail-Fast > Silent Fallback**: if validation fails and a safe default exists (e.g., invalid `DOTFILES` override → `~/.dotfiles`), the answer is warning to stderr + fallback. Never silent fallback; fail-fast only if no safe default.
- **Small, Reversible, Easy-to-Validate Changes > Wide Refactor**: when choosing between structural refactor vs minimal adjacent adjustment, prefer the adjustment. Existing tests must keep signaling during the change, not recover "at the end".
- **Current Architecture > New Complexity for Point Friction**: maintain established module and helper structure unless an improvement needs a specific minimal adjustment. Don't design for hypothetical needs.
- **Don't suggest or use Oh My Zsh (or similar frameworks like Prezto, Zinit, Zim, etc.) in dotfiles.** If functionality is needed (prompts, plugins, completions), implement it directly in `zsh/*.zsh` modules without depending on external frameworks.

### Tactical Cleanup (When Real Friction Appears)

Principles for any future cleanup or "modernization" round:

- Only apply cleanups with demonstrable benefit in clarity or robustness. Cosmetic touches are discarded by default.
- **No cleanup adds more magic, hooks, dynamic evaluation or abstractions than it removes.**
- Small, verifiable units; never a wide refactor "all at once".
- `shellcheck` and `shfmt` are in the Brewfile — manual use is welcome, automating them in shell runtime or `test.sh` is not without justification.

## Immutable Preferences

Closed decisions; don't reopen without explicit request:

- Vanilla zsh. No Oh My Zsh, Prezto, Zinit, Zim or Powerlevel10k. No `zsh-autosuggestions`.
- Prompt: Starship.
- Node: pnpm preferred over npm.
- Editor: `v()` uses vim (**don't suggest nvim**). `s()` (Sublime) is kept alongside `e()` (Zed) by design.
- `gdiff()` is named that way to not override system `diff` (breaks pipes and scripts).
- `WORDCHARS` intentionally excludes `/` and `.` (UX for `Ctrl+W`).

## How to Add New Content

Complete flow, requirements by type (alias, function, completion, etc.) and when to touch tests: **[docs/conventions.md](docs/conventions.md)**.

Summary: new utility → corresponding domain file → row in `docs/reference.md` with first two cells between backticks (anti-drift requirement) → `./test.sh` until green.

## Known Trap: cargo Completions

**Don't use `source <(rustup completions zsh cargo)`**. The `_cargo` file in rustc's sysroot ends with an auto-invocation designed for autoload, not source; sourcing it produces `_arguments:comparguments: can only be called from completion function` on shell startup.

Correct solution (already implemented in `completions.zsh`): add the sysroot to `fpath` before `compinit`:

```zsh
if command -v rustc &>/dev/null; then
    fpath+=("$(rustc --print sysroot)/share/zsh/site-functions")
fi
```

`source <(rustup completions zsh)` (rustup itself) is safe — has `funcstack` guard.

## Known Trap: Brewfile tap declarations

**Don't use** the two-line `tap` + `brew` format for third-party tap formulas:

```ruby
# Wrong — fragile outside brew bundle
tap "getsentry/xcodebuildmcp"
brew "xcodebuildmcp"
```

This works locally when the tap is already installed, but `brew install xcodebuildmcp` on a fresh machine fails with "No available formula" because the tap isn't yet registered.

**Correct** — use the fully-qualified inline path:

```ruby
brew "getsentry/xcodebuildmcp/xcodebuildmcp"
```

Homebrew auto-taps the repo when the formula path is fully qualified. Consistent with all other tap formulas in this repo: `ejoffe/tap/spr`, `withgraphite/tap/graphite`, `anomalyco/tap/opencode`.

## Established Performance Patterns

Respect when adding code; breaking one needs explicit justification:

- **Init caches**: `brew shellenv`, `starship init`, `pyenv init`, `brew --prefix readline/openssl`, `xcrun --show-sdk-path`, `rustc --print sysroot` and completions from `rustup`/`kubectl`/`swiftly`/`pnpm`/`gh` live in `~/.cache/` and regenerate only when the binary is newer than the file. Unified pattern: capture the binary path in a local variable (`BREW_BIN`, `_starship_bin`, `_pyenv_bin`, `bin`) and use `-nt` against it.
- **`~/.cache` created once** in `.zshrc`, before the module loop. All modules (`exports.zsh`, `tools.zsh`, `completions.zsh`, etc.) assume it exists; don't duplicate `mkdir`.
- **Subprocesses in `exports.zsh`** come after a guard (`command -v` or `[ -n "$BREW_BIN" ]`) and are cached to disk. `SDKROOT` is only exported if the cache path is non-empty (xcrun can return `""` with misconfigured CLT and exporting `SDKROOT=""` breaks builds). `xcode-select -s` invalidates the SDKROOT cache: manually delete `~/.cache/xcode_sdkroot` after changing active Xcode.
- **Tool root variables in `exports.zsh` are static paths, not binary queries**: `NVM_DIR`, `SWIFTLY_HOME`, `PYENV_ROOT` are fixed to `"$HOME/.xxx"`, not to `pyenv root` / `nvm --version`. Reason: when `exports.zsh` runs, the binary isn't yet in `PATH` (brew shellenv and `path.zsh` run after). If a tool installs to a non-standard location, the variable is adjusted manually — conscious decision to keep the module free of unnecessary subprocesses.
- **`brew --prefix` not invoked in `path.zsh`**: use variables already cached in `exports.zsh` (e.g., `$OPENSSL_PATH`). `$PATH` is built with zsh array syntax (`path=(... $path)`), not `export PATH=...`.
- **rbenv and nvm lazy**: stubs that self-destruct with `unfunction`/`unset -f` on first use. npm completions registered via `precmd` hook, not sourced inside the stub.
- **Postgres.app**: version detected with native zsh glob + `numeric_glob_sort` in anonymous function; not `ls | sort -V | tail`.
- **`compinit`**: 24h check (`(#qN.mh+24)`) decides between `compinit -C` and regeneration.
- **Atomic cache** in `_cache_completion`: write to `${cache}.tmp.$$` and `mv` only if command succeeds and output is non-empty. Prevents a transient failure from leaving an empty cache. **Not applicable** to init caches (`brew shellenv`, `starship init`, `pyenv init`): those commands have no known transient failures, direct write suffices.

Details and specific historical reasons are in the comments of each file.

## Helper Contracts

**`scripts/check-brewfile.sh`** — validates `Brewfile` without touching the host.

- Exit codes: `0` OK; `10` `brew` not installed; `11` `brew bundle` unavailable; `12` clear host issue when validating; `20` `Brewfile` missing or unreadable; `21` invalid content with clear signal; `22` ambiguous or unclassified failure; `90` internal failure.
- Uses `brew bundle list --all --file=...`, **not** `brew bundle check` — the latter validates installed state too and adds noise beyond the repo's scope.
- Classification `12`/`21`/`22` conservative: both need clear signals, ambiguous falls to `22`. Expand heuristic only on real observed cases; a reproducible `22` should refine the heuristic, not relax the test.
- Initial heuristic patterns:
  - `12` (host) candidates: `Permission denied`, `Operation not permitted`, `Read-only file system`, errors about Homebrew caches/locks/temporaries, errors about Homebrew internal paths, failures of Homebrew runtime itself before Brewfile parsing.
  - `21` (repo) candidates: Brewfile parsing errors, invalid syntax or DSL, malformed entries, unrecognized keywords or types within the file.
  - Heuristic starts small and explicit. **Don't turn it into a large fragile message taxonomy dependent on specific Homebrew versions.**
- Output `OK`: `[OK] Brewfile validation`. Output `FAIL`: `[FAIL] Brewfile validation` + `Suggested fix: <action>` + `Detail: <context>` optional.
- `test.sh` considers pass only exit `0`. `install.sh` uses it as post-install diagnostics: any exit != `0` → warning, doesn't abort basic installation.

**`scripts/check-docs-drift.sh`** — implementation ↔ `docs/reference.md`.

- Exit codes: `0` no drift; `1` drift detected; `90` internal failure.
- Source of truth: the shell implementation. No intermediate inventory.
- Surface scanned v1: `alias NAME=` in `zsh/aliases.zsh` and `function NAME()` in `zsh/functions/*.zsh` (unique style currently). Internal helpers in `zsh/tools.zsh` and `zsh/completions.zsh` **deliberately outside** — load infrastructure, not user utilities.
- Extraction from docs: first token between backticks of rows whose first two columns start with backtick. Tables not following that pattern (tool completions, Brewfile) naturally excluded. **Corollary:** when adding a new row to `docs/reference.md`, if the second column starts with backtick, the check interprets it as a documented alias/function.
- Conscious exclusions: `EXCLUDED_ALIASES`/`EXCLUDED_FUNCTIONS` lists explicit **inside the script itself**, small and auditable. No inline marks in shell, no implicit patterns by prefix or regex.

**`scripts/check-install.sh`** — behavioral validation of `install.sh` in a sandbox.

- Exit codes: `0` OK; `1` incorrect behavior; `90` internal failure.
- Runs `install.sh` with `HOME` redirected to a tempdir via `mktemp -d` + `trap`. Never touches real `$HOME`.
- Validates: (i) five symlinks point to correct repo files, (ii) pre-existing files backed up as `<dst>.bak.YYYYMMDDHHMMSS` with original content preserved, (iii) destinations without prior file don't generate backups, (iv) `~/.gitconfig.local` created from stub, (v) idempotence: second run creates no new backups and reports `[ok]` for five symlinks.
- **Accepted side effect**: `install.sh` at the end invokes `check-brewfile.sh` on the repo's `Brewfile`; its output is informative and doesn't affect the helper's exit code. Not mocked, it's the real-world script behavior.
- Output `OK`: `[OK] install.sh behavior`. Output `FAIL`: `[FAIL] install.sh behavior` + `Suggested fix: <action>` + `Detail: <context>`.

**`scripts/check-runtime-symbols.sh`** — validates that documented symbols are defined after module loading.

- Exit codes: `0` OK; `1` missing symbols at runtime; `90` internal failure.
- **Complements** `check-docs-drift.sh` (static: text comparison) and `module load chain` check (dynamic: absence of stderr). This helper validates **dynamic existence**: after sourcing all modules, each documented symbol must respond to `type`.
- Symbol extraction from docs: same pattern as `check-docs-drift.sh:87-91` (conscious duplication; two uses don't yet justify `scripts/lib/`).
- Subshell zsh sources `.zshenv` + five modules + `zsh/functions/*.zsh` in canonical order. stderr from sources is silenced: this helper doesn't diagnose load errors (checks 3 and 4 do).
- Canonical case captured: a function wrapped (by mistake) in `if command -v foo; then … fi` where the conditional doesn't fire. Drift sees it (textual pattern); this helper marks it missing.
- Requires isolation (`XDG_CACHE_HOME` + `TMPDIR` redirected) when run from `test.sh`, because it sources real modules. Standalone, writes caches to host — accepted for manual debugging.
- Output `OK`: `[OK] runtime symbols check`. Output `FAIL`: `[FAIL] runtime symbols check` + missing symbols list + `Suggested fix: <action>`.

## The Eight Validation Checks

`./test.sh` is the smoke test for the working tree. It runs eight checks in order, each with a specific scope and delegated validation where appropriate:

1. **Bash syntax of `install.sh`** — verifies the installer script is syntactically valid.
2. **Zsh syntax of all modules** — checks `.zshenv`, `.zshrc`, all modules in `zsh/`, and all function files in `zsh/functions/*.zsh` for syntax errors.
3. **Chained module loading** — sources modules in the canonical order (exports → path → tools → node → aliases → completions), verifying they load without stderr and without breaking the load chain. Runs with `XDG_CACHE_HOME` and `TMPDIR` redirected to ephemeral tempdirs.
4. **Loading with `zprof` active** — repeats check 3 with the startup profiler enabled; catches errors that only manifest under profiling. Same tempdir isolation.
5. **Non-destructive Brewfile validation** — delegated to `scripts/check-brewfile.sh`. Validates `Brewfile` syntax and structure without touching the host. Classifies failures as host-level (brew missing, permissions) or repo-level (invalid content).
6. **Anti-drift between implementation and docs** — delegated to `scripts/check-docs-drift.sh`. Ensures every alias in `zsh/aliases.zsh` and function in `zsh/functions/*.zsh` is documented in `docs/reference.md`, and vice versa. Keeps code and docs in sync.
7. **Behavioral validation of `install.sh`** — delegated to `scripts/check-install.sh`. Runs `install.sh` in a sealed temporary `$HOME` and validates symlink creation, backup of pre-existing files with timestamps, and idempotence (running twice produces no new backups).
8. **Runtime symbol validation** — delegated to `scripts/check-runtime-symbols.sh`. After sourcing all modules in canonical order, verifies that every symbol documented in `docs/reference.md` responds to `type` (i.e., is actually defined and callable).

Exit: `0` if all checks pass, `1` if any check fails. The test does not install dependencies or modify the host (except tests 7, which uses a sealed tempdir). The test is designed to catch both implementation errors (missing code, broken loads) and documentation drift (missing or stale docs).

Checks 3, 4, and 8 run with temporary `XDG_CACHE_HOME` and `TMPDIR` to avoid leaving artifacts on the host. Checks 1, 2, 5, 6, 7 are deterministic and don't need isolation.

## Closed Architectural Rationales

Decisions made with explicit rationale; opening them requires reopening the discussion:

- **Partial smoke test isolation**: `test.sh` redirects `XDG_CACHE_HOME` and `TMPDIR` to an ephemeral tempdir only for checks that load real modules. `HOME` and `ZDOTDIR` are **deliberately preserved** — the smoke test sources modules directly (not `zsh -i`), redirecting `ZDOTDIR` would leave checks without accessible `.zshrc` and `.zshenv` and provides no real isolation over problematic writes. Purely syntactic checks don't need isolation.
- **`install.sh` doesn't self-remedy the host**: can warn and suggest `mv` when root doesn't match `~/.dotfiles`, but doesn't move or copy automatically. `~/.dotfiles` is recommended canonical location, not hard requirement. Script resolves active root via `DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` and can run from any local clone.
- **`DOTFILES` override is explicit opt-in**: no auto-detection or automatic path search. Minimal validation: existing directory + readable `.zshrc` + readable `.zshenv`. If invalid → warning to stderr + fallback to `~/.dotfiles`. Ergonomics, not `./test.sh` substitute. `.zshenv` still loads from `~/.zshenv` (override only affects resolution within the already-installed `.zshrc`).
- **CI ignores Homebrew by design**: `.github/workflows/ci.yml` runs `./test.sh` with `SKIP_BREWFILE=1` on `macos-latest`, on push to `main` and `pull_request`. Minimal permissions (`contents: read`), concurrency by `github.ref` with obsolete run cancellation, 10-min timeout. No caches, no third-party actions beyond `actions/checkout@v4`. `SKIP_BREWFILE` **must not be defined locally**. If Homebrew coverage is added, it will be a separate, non-blocking job.
- **Single validation entry point**: `./test.sh` is the only main entry point. Don't add new modes or flags unless there's a real, incontestable need. `SKIP_BREWFILE` is the sole exception and skips one check, doesn't change order or logic.

## Additional Documentation

- [docs/setup.md](docs/setup.md) — expected environment and installation flow from scratch
- [docs/conventions.md](docs/conventions.md) — **requirements for adding aliases, functions and test flow**
- [docs/reference.md](docs/reference.md) — exhaustive reference (aliases, functions, completions, Brewfile packages, `./test.sh` with eight checks, `DOTFILES`, `SKIP_BREWFILE`, CI)
- [docs/swift.md](docs/swift.md) — Swiftly vs Xcode
- If using XcodeBuildMCP, use the installed XcodeBuildMCP skill before calling XcodeBuildMCP tools.
