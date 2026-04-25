#!/usr/bin/env bash
# scripts/check-runtime-symbols.sh — validates that each alias/function
# documented in docs/reference.md actually exists after sourcing the shell modules.
#
# Complements scripts/check-docs-drift.sh (which is static: compares text
# patterns between implementation and docs) with a dynamic verification: after
# loading .zshenv + the zsh/ modules + zsh/functions/*.zsh in the same order
# that .zshrc uses, each documented symbol must respond to `type`.
#
# Canonical case captured: a function accidentally wrapped in an
# `if command -v foo; then ... fi` whose condition does not fire. The static
# drift check sees it (the `function NAME()` pattern appears in the file);
# this helper marks it as missing.
#
# Usage:
#   ./scripts/check-runtime-symbols.sh
#
# Exit codes:
#   0   all documented symbols exist after loading
#   1   documented symbols that do not respond to `type` after loading
#   90  internal failure (missing files or empty extraction)
#
# Output format:
#   OK    "[OK] runtime symbols check"
#   FAIL  "[FAIL] runtime symbols check"
#         "Symbols in docs/reference.md but not defined at runtime after sourcing all modules:"
#         "  - <sym>" (one per line)
#         "Suggested fix: <action>"
#
# Side effects: this helper performs a real `source` of the modules, which may
# trigger init caches (brew shellenv, starship init, pyenv init) that write to
# ~/.cache/. When run from test.sh, the caller wraps it with run_isolated
# (XDG_CACHE_HOME and TMPDIR redirected); when run standalone, caches are
# written to the real host — acceptable for manual debugging use.
#
# Module load stderr is silenced: this helper does not diagnose loading errors
# (that is the responsibility of checks 3/4 in test.sh). If a module aborts
# mid-load, subsequent symbols will be missing and appear in the list.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

DOCS_FILE="docs/reference.md"

die_internal() {
    echo "[FAIL] runtime symbols check"
    echo "Suggested fix: $1"
    exit 90
}

[[ -r "$DOCS_FILE" ]] || die_internal "restore $DOCS_FILE in the working tree."

# Extract documented symbols: first backtick-quoted token in table rows whose
# first two columns both start with a backtick.
# Conscious duplication of scripts/check-docs-drift.sh:87-91 — the same table
# text pattern applies here. If a third use appears, reconsider factoring into
# scripts/lib/ (currently premature).
documented=$(
    grep -E '^\|[[:space:]]+`[^`]+`[[:space:]]+\|[[:space:]]+`' "$DOCS_FILE" \
        | sed -E 's/^\|[[:space:]]+`([^`]+)`.*/\1/' \
        | sort -u
)

[[ -n "$documented" ]] || die_internal "no symbols extracted from $DOCS_FILE — check the table format (rows need backticks in the first two columns)."

# Sources the modules in a zsh subshell in the same order as .zshrc and as
# check 3 in test.sh (literal copy of chain_script, test.sh:77-85).
# Iterates over symbols passed via env var and reports those that `type` does
# not recognize after loading.
missing=$(
    DOCUMENTED_SYMBOLS="$documented" zsh -c '
        source .zshenv 2>/dev/null
        for cfg in zsh/exports.zsh zsh/path.zsh zsh/tools.zsh zsh/node.zsh zsh/aliases.zsh zsh/completions.zsh; do
            source "$cfg" 2>/dev/null
        done
        for cfg in zsh/functions/*.zsh; do
            source "$cfg" 2>/dev/null
        done

        # ${=var} enables word splitting in zsh (equivalent to bash implicit splitting).
        # type recognizes aliases, functions, builtins and externals; exit code suffices.
        for sym in ${=DOCUMENTED_SYMBOLS}; do
            type -- "$sym" >/dev/null 2>&1 || echo "$sym"
        done
    '
)

if [[ -z "$missing" ]]; then
    echo "[OK] runtime symbols check"
    exit 0
fi

echo "[FAIL] runtime symbols check"
echo "Symbols in $DOCS_FILE but not defined at runtime after sourcing all modules:"
while IFS= read -r sym; do
    echo "  - $sym"
done <<< "$missing"
echo "Suggested fix: ensure each documented alias/function is unconditionally defined in its module (or remove/correct the conditional that skipped it). The module load check (check 3) may offer additional context if loading itself is failing."
exit 1
