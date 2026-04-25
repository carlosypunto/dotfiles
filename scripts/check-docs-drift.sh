#!/usr/bin/env bash
# scripts/check-docs-drift.sh — detects drift between actual aliases/functions
# in the repo and what is documented in docs/reference.md.
#
# Source of truth: the shell implementation.
#   - Aliases:   zsh/aliases.zsh
#   - Functions: zsh/functions/*.zsh
# Documented target: docs/reference.md.
#
# Usage:
#   ./scripts/check-docs-drift.sh
#
# Exit codes:
#   0   no drift
#   1   drift detected (list of missing or extra symbols)
#   90  internal helper failure (missing or unreadable files)
#
# Output format:
#   OK    one line "[OK] docs drift check".
#   FAIL  "[FAIL] docs drift check"
#         "Symbols in implementation but not in docs/reference.md:" (optional)
#         "Symbols in docs/reference.md but not in implementation:" (optional)
#         "Suggested fix: <action>".
#
# What to do when it fails:
#   - New symbol in the implementation that is relevant to the user → add a
#     row in docs/reference.md in the corresponding section.
#   - Obsolete symbol in docs → remove the row.
#   - Internal symbol with no public value → add it to EXCLUDED_ALIASES or
#     EXCLUDED_FUNCTIONS below with a brief justification comment.
#
# Design rules (Phase 4, v1):
#   - Single source of truth: the implementation. No intermediate inventory.
#   - Exclusions are explicit, small lists inside this script.
#   - No inline markers in shell files, no implicit patterns by prefix or regex
#     that hide intent.
#   - v1 only covers docs/reference.md; README.md and docs/setup.md are out of scope.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

ALIASES_FILE="zsh/aliases.zsh"
FUNCTIONS_DIR="zsh/functions"
DOCS_FILE="docs/reference.md"

# ─── Conscious exclusions ─────────────────────────────────────────────────────
# Add a symbol here only when it exists in the implementation but does not
# deserve public documentation in docs/reference.md. Use the exact name with a
# brief justification comment. Keep these lists small and auditable.
EXCLUDED_ALIASES=()
EXCLUDED_FUNCTIONS=()

die_internal() {
    echo "[FAIL] docs drift check"
    echo "Suggested fix: $1"
    exit 90
}

[[ -r "$ALIASES_FILE"  ]] || die_internal "restore $ALIASES_FILE in the working tree."
[[ -r "$DOCS_FILE"     ]] || die_internal "restore $DOCS_FILE in the working tree."
[[ -d "$FUNCTIONS_DIR" ]] || die_internal "restore $FUNCTIONS_DIR/ in the working tree."

# ─── Extraction ───────────────────────────────────────────────────────────────
# Aliases defined in the aliases module. Covers `alias NAME=` at the start of
# a line (with optional indentation). Comments start with `#` and don't start
# with `alias`, so they don't match.
impl_aliases=$(
    grep -E '^[[:space:]]*alias [A-Za-z_][A-Za-z0-9_-]*=' "$ALIASES_FILE" \
        | sed -E 's/^[[:space:]]*alias ([A-Za-z_][A-Za-z0-9_-]*)=.*/\1/' \
        | sort -u
)

# Functions declared as `function NAME()` in any file under zsh/functions/.
# This is the only style currently used in the repo; if another style is
# introduced (`NAME()` without the keyword), extend this pattern deliberately.
impl_functions=$(
    grep -hE '^[[:space:]]*function [A-Za-z_][A-Za-z0-9_-]*[[:space:]]*\(\)' "$FUNCTIONS_DIR"/*.zsh \
        | sed -E 's/^[[:space:]]*function ([A-Za-z_][A-Za-z0-9_-]*).*/\1/' \
        | sort -u
)

# Documented symbols: first backtick-quoted token in table rows whose second
# field also starts with a backtick. This excludes tables whose first column is
# not a symbol (e.g. the completions table with "Docker", "cargo", etc.).
# Variable spacing between cells is tolerated (some rows align with extra spaces).
documented=$(
    grep -E '^\|[[:space:]]+`[^`]+`[[:space:]]+\|[[:space:]]+`' "$DOCS_FILE" \
        | sed -E 's/^\|[[:space:]]+`([^`]+)`.*/\1/' \
        | sort -u
)

# ─── Exclusion list composition ───────────────────────────────────────────────
# ${#arr[@]} is safe with `set -u` even when the array is empty.
all_excluded=$(
    {
        if (( ${#EXCLUDED_ALIASES[@]} > 0 )); then
            printf '%s\n' "${EXCLUDED_ALIASES[@]}"
        fi
        if (( ${#EXCLUDED_FUNCTIONS[@]} > 0 )); then
            printf '%s\n' "${EXCLUDED_FUNCTIONS[@]}"
        fi
    } | sort -u
)

impl_all=$(printf '%s\n%s\n' "$impl_aliases" "$impl_functions" | sort -u)

# Candidates that should be documented = impl − exclusions.
if [[ -n "$all_excluded" ]]; then
    impl_documentable=$(comm -23 <(printf '%s\n' "$impl_all") <(printf '%s\n' "$all_excluded"))
else
    impl_documentable="$impl_all"
fi

# ─── Drift calculation ────────────────────────────────────────────────────────
# Missing from docs: implemented symbol (not excluded) that is not documented.
missing_from_docs=$(
    comm -23 \
        <(printf '%s\n' "$impl_documentable") \
        <(printf '%s\n' "$documented")
)

# Missing from implementation: documented symbol that does not exist in the raw
# implementation (including exclusions, to avoid confusing "excluded" with "absent").
missing_from_impl=$(
    comm -23 \
        <(printf '%s\n' "$documented") \
        <(printf '%s\n' "$impl_all")
)

if [[ -z "$missing_from_docs" && -z "$missing_from_impl" ]]; then
    echo "[OK] docs drift check"
    exit 0
fi

echo "[FAIL] docs drift check"
if [[ -n "$missing_from_docs" ]]; then
    echo "Symbols in implementation but not in $DOCS_FILE:"
    while IFS= read -r sym; do
        echo "  - $sym"
    done <<< "$missing_from_docs"
fi
if [[ -n "$missing_from_impl" ]]; then
    echo "Symbols in $DOCS_FILE but not in implementation:"
    while IFS= read -r sym; do
        echo "  - $sym"
    done <<< "$missing_from_impl"
fi
echo "Suggested fix: update $DOCS_FILE to match the implementation, or add the symbol to the EXCLUDED_* list in scripts/check-docs-drift.sh with a brief justification."
exit 1
