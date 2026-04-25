#!/usr/bin/env bash
# test.sh — smoke test for the dotfiles repository.
#
# Checks:
#   1. Bash syntax of install.sh
#   2. Zsh syntax of .zshenv, .zshrc, modules and functions
#   3. Chained module loading in the order .zshrc uses
#   4. Profiler (ZPROF) runs without errors
#   5. Brewfile valid — delegated to scripts/check-brewfile.sh
#   6. Anti-drift of docs/reference.md — delegated to scripts/check-docs-drift.sh
#   7. install.sh behavior — delegated to scripts/check-install.sh
#   8. Runtime symbols — delegated to scripts/check-runtime-symbols.sh
#
# Usage:
#   ./test.sh
#   SKIP_BREWFILE=1 ./test.sh   # skips check 5 (intended for CI)
#
# Exit code: 0 if everything passes, 1 if anything fails.
#
# Known limitation: does NOT run `zsh -i -c exit`, because that command loads
# the installed ~/.zshrc (which may be symlinked to another repo), not this
# working tree. Check 3 simulates the .zshrc orchestration directly.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

PASS=0
FAIL=0
FAILED=()

# Minimal isolation for checks that perform real module loading and zprof.
# Only XDG_CACHE_HOME and TMPDIR are redirected so those checks don't write
# caches or temp files on the host. HOME is kept (redirecting it would distance
# the test from the repo's real runtime behavior). ZDOTDIR is kept intentionally:
# checks source modules explicitly from the working tree and don't invoke
# `zsh -i`, so redirecting it adds no real isolation and would break .zshrc/.zshenv
# resolution. Pure syntax checks (zsh -n, bash -n) don't use this.
ISOLATED_ROOT=$(mktemp -d -t dotfiles-test.XXXXXX)
mkdir -p "$ISOLATED_ROOT/cache" "$ISOLATED_ROOT/tmp"
trap 'rm -rf "$ISOLATED_ROOT"' EXIT

# Wraps a command with XDG_CACHE_HOME and TMPDIR redirected to this run's
# tempdir. Use for any check that does a real `source` of the modules.
run_isolated() {
    env XDG_CACHE_HOME="$ISOLATED_ROOT/cache" TMPDIR="$ISOLATED_ROOT/tmp" "$@"
}

# Runs a check capturing stdout+stderr; shows them only on failure.
check() {
    local name="$1"
    shift
    local out
    if out=$("$@" 2>&1); then
        echo "[PASS] $name"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $name"
        [[ -n "$out" ]] && echo "$out" | sed 's/^/        /'
        FAIL=$((FAIL + 1))
        FAILED+=("$name")
    fi
}

echo "Dotfiles repository smoke test"
echo "────────────────────────────────"

# 1. Installer syntax
check "install.sh: syntax" bash -n install.sh

# 2. Syntax of each zsh file
for f in .zshenv .zshrc zsh/*.zsh zsh/functions/*.zsh; do
    check "zsh -n $f" zsh -n "$f"
done

# 3. Chained module loading (replicates .zshrc order).
# Validated by absence of stderr, not exit code: _cache_completion returns
# != 0 when an optional binary (swiftly, etc.) is not installed, which is
# expected behavior, not an error.
chain_script='
    source .zshenv
    for cfg in zsh/exports.zsh zsh/path.zsh zsh/tools.zsh zsh/node.zsh zsh/aliases.zsh zsh/completions.zsh; do
        source "$cfg"
    done
    for cfg in zsh/functions/*.zsh; do
        source "$cfg"
    done
'

check_no_stderr() {
    local name="$1"; shift
    local out
    out=$("$@" 2>&1 >/dev/null)
    if [[ -z "$out" ]]; then
        echo "[PASS] $name"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $name"
        echo "$out" | sed 's/^/        /'
        FAIL=$((FAIL + 1))
        FAILED+=("$name")
    fi
}

check_no_stderr "module load chain" run_isolated zsh -c "$chain_script"

# 4. Active profiler — useful for catching errors that only appear with zprof
check_no_stderr "zprof load" run_isolated zsh -c "
    zmodload zsh/zprof
    $chain_script
    zprof > /dev/null
"

# 5. Brewfile — validation delegated to scripts/check-brewfile.sh.
# The helper classifies host failure vs repo failure and produces a
# `Suggested fix` line. test.sh considers only exit 0 a pass; any other
# result is a fail, including the case where the helper is not invocable
# (repo or integration problem, not a host problem). The helper's output is
# preserved as-is: it already includes "[OK]"/"[FAIL] Brewfile validation"
# and needs no reformatting.
#
# SKIP_BREWFILE opt-out: sole escape hatch, intended for CI (Phase 5). Keeps
# Homebrew off the critical path in environments where its state is not part
# of the repo contract (e.g. the GitHub macOS runner, which ships brew
# pre-installed but at host versions that don't represent the user's env).
# Not a "mode": it doesn't change check order or activate different logic.
# In local development it should be left unset so the smoke test keeps
# covering Brewfile validation.
BREWFILE_HELPER="./scripts/check-brewfile.sh"
if [[ -n "${SKIP_BREWFILE:-}" ]]; then
    echo "[SKIP] Brewfile validation (SKIP_BREWFILE set)"
elif [[ -x "$BREWFILE_HELPER" ]]; then
    helper_output=$("$BREWFILE_HELPER" Brewfile 2>&1)
    helper_rc=$?
    echo "$helper_output"
    if [[ $helper_rc -eq 0 ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        FAILED+=("Brewfile validation")
    fi
else
    echo "[FAIL] Brewfile validation"
    echo "Suggested fix: restore the helper script permissions or repository contents, then rerun ./test.sh."
    echo "Detail: scripts/check-brewfile.sh is missing or not executable."
    FAIL=$((FAIL + 1))
    FAILED+=("Brewfile validation")
fi

# 6. Docs drift — validation delegated to scripts/check-docs-drift.sh.
# Compares aliases in zsh/aliases.zsh and functions in zsh/functions/*.zsh against
# what is documented in docs/reference.md. Exit 0 => pass; any other code is
# a fail, including the case where the helper is not invocable. The helper's
# output already includes "[OK]"/"[FAIL] docs drift check" and a Suggested fix
# line; preserved as-is.
DOCS_HELPER="./scripts/check-docs-drift.sh"
if [[ -x "$DOCS_HELPER" ]]; then
    docs_output=$("$DOCS_HELPER" 2>&1)
    docs_rc=$?
    echo "$docs_output"
    if [[ $docs_rc -eq 0 ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        FAILED+=("docs drift check")
    fi
else
    echo "[FAIL] docs drift check"
    echo "Suggested fix: restore the helper script permissions or repository contents, then rerun ./test.sh."
    echo "Detail: scripts/check-docs-drift.sh is missing or not executable."
    FAIL=$((FAIL + 1))
    FAILED+=("docs drift check")
fi

# 7. install.sh — behavioral validation delegated to scripts/check-install.sh.
# The helper runs install.sh in a sealed temporary $HOME and validates symlink
# creation, backup of pre-existing files, and idempotency. Does not touch the
# real $HOME. Same exit code and output contract as checks 5 and 6.
INSTALL_HELPER="./scripts/check-install.sh"
if [[ -x "$INSTALL_HELPER" ]]; then
    install_output=$("$INSTALL_HELPER" 2>&1)
    install_rc=$?
    echo "$install_output"
    if [[ $install_rc -eq 0 ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        FAILED+=("install.sh behavior")
    fi
else
    echo "[FAIL] install.sh behavior"
    echo "Suggested fix: restore the helper script permissions or repository contents, then rerun ./test.sh."
    echo "Detail: scripts/check-install.sh is missing or not executable."
    FAIL=$((FAIL + 1))
    FAILED+=("install.sh behavior")
fi

# 8. Runtime symbols — validation delegated to scripts/check-runtime-symbols.sh.
# Verifies that each alias/function documented in docs/reference.md actually
# exists after sourcing the modules. Complements the drift check (static) and
# the module load chain (only absence of stderr). Uses run_isolated because
# the helper sources the modules and could write caches on the host.
SYMBOLS_HELPER="./scripts/check-runtime-symbols.sh"
if [[ -x "$SYMBOLS_HELPER" ]]; then
    symbols_output=$(run_isolated "$SYMBOLS_HELPER" 2>&1)
    symbols_rc=$?
    echo "$symbols_output"
    if [[ $symbols_rc -eq 0 ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        FAILED+=("runtime symbols check")
    fi
else
    echo "[FAIL] runtime symbols check"
    echo "Suggested fix: restore the helper script permissions or repository contents, then rerun ./test.sh."
    echo "Detail: scripts/check-runtime-symbols.sh is missing or not executable."
    FAIL=$((FAIL + 1))
    FAILED+=("runtime symbols check")
fi

echo "────────────────────────────────"
echo "Total: $((PASS + FAIL)) — $PASS pass, $FAIL fail"

if (( FAIL > 0 )); then
    echo ""
    echo "Failed:"
    for t in "${FAILED[@]}"; do
        echo "  - $t"
    done
    exit 1
fi

exit 0
