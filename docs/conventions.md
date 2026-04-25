# Conventions — How to Add New Content

Guide to adding aliases and functions to the repo, documenting them and making sure `./test.sh` passes.

| I want to add… | File |
|---|---|
| Environment variable | `zsh/exports.zsh` |
| Entry in `$PATH` | `zsh/path.zsh` |
| Tool initialization (`eval`, scripts) | `zsh/tools.zsh` |
| Alias | `zsh/aliases.zsh` |
| Tool completion | `zsh/completions.zsh` |
| Shell option (`setopt`) | Block `# ─── Shell options ───` at the end of `.zshrc` |
| Generic utility function | `zsh/functions/general.zsh` |
| Domain-specific function | `zsh/functions/<domain>.zsh` |
| Functions for a new domain | Create `zsh/functions/<domain>.zsh` — it loads automatically |

> **Note:** pnpm is the preferred Node package manager over npm. Use `pnpm` instead of `npm` whenever possible.

---

## Requirements for Adding a New Alias

### 1. Declare it in `zsh/aliases.zsh`

Write your alias with this pattern:

```zsh
alias NAME='command'
```

- The name must start with a letter or `_`, followed by `[A-Za-z0-9_-]`.
- The section of the file is organized by domain (`# ─── Git ───`, `# ─── Docker ───`, …). Place the alias in the corresponding block; if the domain doesn't exist, create a new block with the same separator style.
- Conditional assignments (e.g., the block `if command -v eza` for `ls`/`ll`/`la`) also count: each branch of the `if` must follow the `alias NAME=…` pattern.
- Brief inline comments are welcome; they don't affect the anti-drift check (the check that keeps code and docs in sync).

### 2. Document it in `docs/reference.md`

The anti-drift check (the check that keeps code and docs in sync) extracts documented symbols from table rows whose **first and second field** start with backticks. The row must have this exact form:

```markdown
| `NAME` | `command or usage` | Brief description |
```

- Add the row in the table for the correct domain (Git, Docker, kubectl, …). If the domain doesn't exist in `docs/reference.md`, create a new sub-block following the style of existing ones.
- If the first column doesn't use backticks, the check won't see that row as documentation (desired behavior for informational tables like the one for tool completions).

### 3. If the alias is internal and doesn't merit public documentation

Add its name to `EXCLUDED_ALIASES` in `scripts/check-docs-drift.sh`, with a brief comment justifying the exclusion. This list should be kept small and auditable; it's not a mechanism to silence real drift.

---

## Requirements for Adding a New Function

### 1. Declare it in `zsh/functions/<domain>.zsh`

The function must use the `function NAME()` style at the beginning of a line. It's the only pattern the anti-drift check recognizes, and it matches the style used throughout the repo:

```zsh
# Brief description; `Usage:` with a concrete example.
function NAME() {
    # body
}
```

- Internal comments are in English (global rule from CLAUDE.md). The function header is in the same language as other documentation.
- The name must start with a letter or `_`, followed by `[A-Za-z0-9_-]`.
- If the function depends on an optional tool, wrap the definition in a `command -v`/`hash` guard:

    ```zsh
    if hash git &>/dev/null; then
        function gdiff() { … }
    fi
    ```

- **New domain**: create `zsh/functions/<domain>.zsh`. It loads automatically via the `zsh/functions/*.zsh` glob in `.zshrc`; no manual registration needed.
- **Unrecognized patterns**: declarations like `NAME() { … }` without the `function` keyword are intentionally outside the check. If that style is ever adopted, the regex in `scripts/check-docs-drift.sh` must be deliberately extended.

### 2. Document it in `docs/reference.md`

Same rule as for aliases: table row with the first two fields between backticks.

```markdown
| `NAME` | `NAME arg`       | Brief description |
```

The "Functions" section of the file has one table per domain (`### Git (git.zsh)`, `### Docker (docker.zsh)`, …). Use the same one if the domain already exists, or add a new sub-section following the same pattern.

### 3. If the function is internal (load helper, not a user utility)

Two options:

- If it lives inside `zsh/tools.zsh` or `zsh/completions.zsh` **and** is not declared with `function NAME()` in any file inside `zsh/functions/*.zsh`, the check won't see it — that's the expected case for load infrastructure (`_load_nvm`, `_cache_completion`, etc.). Only `functions/*.zsh` is checked because those are user-facing utilities; infrastructure helpers in `tools.zsh` and `completions.zsh` are intentionally excluded.
- If for some reason it must live in `zsh/functions/*.zsh` but doesn't merit docs (rare case), add it to `EXCLUDED_FUNCTIONS` in `scripts/check-docs-drift.sh` with a brief comment.

---

## Documentation in `docs/reference.md`: Rules that Apply to the Check

The anti-drift check (`scripts/check-docs-drift.sh`) compares real symbols against what's documented. For a row to count as documentation of a symbol:

- It must be a **markdown table row**: starts with `|`, has at least two cells separated by `|`.
- **First and second cell between backticks**: `` | `NAME` | `…` | … ``. If the second cell doesn't use backticks, the row is ignored (this avoids tables like the completions one, with "Docker", "cargo" in the first column without backticks, generating false positives).
- The extracted value is the first token between backticks of the first cell.

Practical consequence: when you write the description, reserve backticks for the command or example. The explanatory phrase goes in the third cell without backticks around the symbol.

---

## Complete Flow for Adding an Alias or Function

Steps in order. Don't skip `./test.sh`: it's the only point that detects drift before committing.

1. **Implement**
   - Alias → `zsh/aliases.zsh`.
   - Function → `zsh/functions/<domain>.zsh` (create the file if the domain doesn't exist).
   - Respect the exact pattern (`alias NAME=…` / `function NAME() { … }`) so the check recognizes it.
2. **Document**
   - Add the corresponding row in the table for the domain in `docs/reference.md`.
   - If the symbol is strictly internal, add it to the `EXCLUDED_*` list in `scripts/check-docs-drift.sh` instead of docs.
3. **Validate Locally**
   ```zsh
   ./test.sh
   ```
   Must pass all eight checks:
   1. Bash syntax of `install.sh`.
   2. Zsh syntax of `.zshenv`, `.zshrc`, modules and functions.
   3. Chained module loading (minimal isolation: `XDG_CACHE_HOME` and `TMPDIR` in a tempdir).
   4. Loading with `zprof` active.
   5. Brewfile validation (delegated to `scripts/check-brewfile.sh`).
   6. Anti-drift of `docs/reference.md` (delegated to `scripts/check-docs-drift.sh`).
   7. Behavior of `install.sh` in a sandbox (delegated to `scripts/check-install.sh`).
   8. Runtime validation of documented symbols (delegated to `scripts/check-runtime-symbols.sh`).
4. **Resolve a Check 6 Failure** (most likely when adding new code):
   - `Symbols in implementation but not in docs/reference.md: X` → missing row in `docs/reference.md`, or the symbol is internal and should go in the `EXCLUDED_*` list.
   - `Symbols in docs/reference.md but not in implementation: X` → row exists in docs but symbol is not defined (typical when renaming or deleting). Update docs.
5. **Test Behavior in a Real Shell** (optional but recommended for functions):
   ```zsh
   exec zsh             # reloads the active shell
   NAME arg             # use the new function/alias
   ```
   `./test.sh` covers syntax and loading, not execution of each function.
6. **Commit** only when `./test.sh` passes with exit `0`.

---

## When and How to Modify Tests

The normal flow **doesn't** require touching `test.sh` or the helpers. Adding aliases/functions only needs steps 1-2 from above. Cases where tests do need updating:

### Case 1 — A Symbol Exists in Implementation but Shouldn't be Documented

Edit `scripts/check-docs-drift.sh` and add it to `EXCLUDED_ALIASES` or `EXCLUDED_FUNCTIONS`, with a brief comment justifying it. Keep these lists small and auditable; if they grow it signals the documentation convention is being evaded.

### Case 2 — A New Declaration Style is Adopted

The check recognizes exactly `alias NAME=…` and `function NAME()`. If, for example, `NAME() { … }` without the keyword is introduced, or dynamically generated aliases, the pattern-matching in `scripts/check-docs-drift.sh` must be deliberately extended. The rule: change the regex only when the new style is a conscious design decision, not to silence a one-off case.

### Case 3 — A New Alias or Function Module is Added

- Functions: just create `zsh/functions/<domain>.zsh`. The `zsh/functions/*.zsh` glob already includes it in check 3 of `test.sh` and in the helper's regex.
- Aliases: the repo uses **a single** `zsh/aliases.zsh` file by explicit decision. If a real reason appears to split it, extend `ALIASES_FILE` in `scripts/check-docs-drift.sh` (switch to glob) and leave a brief note in this document.

### Case 4 — A New Check is Added in `test.sh`

- Checks that do real module `source` must pass through `run_isolated` to inherit the `XDG_CACHE_HOME` and `TMPDIR` redirection.
- Purely syntactic checks (`zsh -n`, `bash -n`) don't need isolation.
- A new check depending on a helper in `scripts/` must follow the same contract as existing ones: exit `0` = pass, any other value = fail (including the helper being uninvocable), and preserve the helper's output without reformatting.

### Case 5 — A Dependency is Added to the `Brewfile`

No need to touch the test. `scripts/check-brewfile.sh` only validates parsing, not installed state. Check locally (`brew bundle --file=Brewfile`) if you want to ensure installation, but that check stays outside `./test.sh`.

### Case 6 — CI

`.github/workflows/ci.yml` runs `./test.sh` with `SKIP_BREWFILE=1` on `macos-latest`. If a change introduces a new host dependency that the clean runner can't satisfy, the correct option is to **adapt the check** (or isolate it more) in `test.sh` itself, not add a new exception in CI. `SKIP_BREWFILE` is the only one-off opt-out accepted.

---

## Quick Checklist Before Committing

- [ ] Alias declared with `alias NAME=…` / function with `function NAME() { … }`.
- [ ] Row added to `docs/reference.md` with first and second cell between backticks, or symbol added to `EXCLUDED_*` with justification.
- [ ] `./test.sh` passes with exit `0` and without `[FAIL]` lines.
- [ ] (Optional, recommended) tested in an interactive shell (`exec zsh` + actual use).
