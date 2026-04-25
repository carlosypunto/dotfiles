#!/usr/bin/env bash
# scripts/check-brewfile.sh — non-destructive Brewfile diagnostic.
#
# Usage:
#   scripts/check-brewfile.sh <path_to_Brewfile>
#
# Exit codes:
#   0   OK
#   10  brew not installed
#   11  brew bundle not available
#   12  Homebrew environment prevents normal validation (host problem)
#   20  Brewfile missing or unreadable
#   21  invalid Brewfile content (clear signal)
#   22  unclassified validation failure (host vs repo ambiguous)
#   90  internal helper failure
#
# Output format:
#   OK     one line "[OK] Brewfile validation"
#   FAIL   "[FAIL] Brewfile validation"
#          "Suggested fix: <action>"
#          "Detail: <context>"   (optional)
#
# Design rules: non-destructive validation (no installs or host modifications),
# short and stable output reusable by test.sh and install.sh, small initial
# heuristic that is only expanded from real observed failures.

set -uo pipefail

fail() {
    local code="$1"
    local suggest="$2"
    local detail="${3:-}"
    echo "[FAIL] Brewfile validation"
    echo "Suggested fix: $suggest"
    [[ -n "$detail" ]] && echo "Detail: $detail"
    exit "$code"
}

ok() {
    echo "[OK] Brewfile validation"
    exit 0
}

if [[ $# -ne 1 ]]; then
    fail 90 "invoke scripts/check-brewfile.sh with the path to a Brewfile as the only argument." \
         "expected 1 argument, got $#."
fi

BREWFILE="$1"

# 1. brew available on the host.
if ! command -v brew &>/dev/null; then
    fail 10 "install Homebrew (https://brew.sh) and rerun ./test.sh." \
         "brew not found in PATH."
fi

# 2. brew bundle support available.
# `brew help bundle` returns 0 when bundle is a recognized subcommand and != 0
# when brew doesn't know the subcommand (tap missing or broken runtime).
if ! brew help bundle &>/dev/null; then
    fail 11 "install or enable homebrew-bundle support (e.g. 'brew tap homebrew/bundle') and rerun ./test.sh." \
         "brew is installed but 'brew bundle' is not available."
fi

# 3. Brewfile accessible from this active root.
if [[ ! -f "$BREWFILE" || ! -r "$BREWFILE" ]]; then
    fail 20 "check that the Brewfile exists and is readable at the path provided." \
         "Brewfile not found or not readable: $BREWFILE"
fi

# 4. Non-destructive validation. `brew bundle list --all --file=...` parses the
# file and lists entries without touching the installed state of the host.
# `brew bundle check` is not used because it mixes file validity with system state.
validation_output=$(brew bundle list --all --file="$BREWFILE" 2>&1)
validation_rc=$?

if [[ $validation_rc -eq 0 ]]; then
    ok
fi

# 5. Conservative failure classification.
# Small initial heuristic; only expanded from real observed cases.
host_patterns='Permission denied|Operation not permitted|Read-only file system|unable to (create|write|access)|cannot (create|write|access)|No such file or directory.*/(Cellar|Caskroom|Homebrew|Library/Homebrew|Library/Caches/Homebrew)|lock(file)?|/tmp/'
brewfile_patterns='parse error|syntax error|unexpected (token|keyword|symbol)|unrecognized (line|entry|keyword)|[Ii]nvalid (line|Brewfile)|unknown (type|keyword)|undefined (method|local variable)|NoMethodError|uninitialized constant'

first_line=$(printf '%s\n' "$validation_output" | sed -n '1p')

if printf '%s\n' "$validation_output" | grep -qE "$host_patterns"; then
    fail 12 "review the Homebrew runtime and local caches/permissions, fix the host state, and rerun ./test.sh." \
         "$first_line"
fi

if printf '%s\n' "$validation_output" | grep -qE "$brewfile_patterns"; then
    fail 21 "review the Brewfile entries reported by Homebrew and fix the invalid content." \
         "$first_line"
fi

fail 22 "review the Homebrew error below, classify it as host or Brewfile issue, fix that cause, and rerun ./test.sh." \
     "$first_line"
