#!/usr/bin/env bash
# scripts/check-install.sh — behavioral validation of install.sh.
#
# Runs install.sh in a sealed temporary $HOME and verifies that:
#   1. The five symlinks are created pointing to the correct repo file.
#   2. Pre-existing files are backed up as <dst>.bak.YYYYMMDDHHMMSS.
#   3. Destinations with no prior file do not generate a backup.
#   4. ~/.gitconfig.local is created from the stub when it does not exist.
#   5. install.sh is idempotent: a second run creates no new backups and
#      reports [ok] for all five symlinks.
#
# Usage:
#   ./scripts/check-install.sh
#
# Exit codes:
#   0   correct behavior
#   1   incorrect behavior (detail in Suggested fix / Detail)
#   90  internal helper failure (missing files, mktemp, etc.)
#
# Output format:
#   OK    "[OK] install.sh behavior"
#   FAIL  "[FAIL] install.sh behavior"
#         "Suggested fix: <action>"
#         "Detail: <context>"  (optional)
#
# Safety: the helper never touches the real $HOME. Redirects HOME to a per-run
# tempdir via mktemp -d + trap. install.sh at the end invokes check-brewfile.sh
# on the repo Brewfile; its output is informational and does not block the test.

set -uo pipefail

# Resolve repo root from the script's location.
REPO="$(cd "$(dirname "$0")/.." && pwd)" || {
    echo "[FAIL] install.sh behavior"
    echo "Suggested fix: run the helper from within the repository tree."
    echo "Detail: could not resolve repo root from \$0=$0."
    exit 90
}

INSTALL_SH="$REPO/install.sh"
[[ -x "$INSTALL_SH" ]] || {
    echo "[FAIL] install.sh behavior"
    echo "Suggested fix: restore executable permissions on install.sh."
    echo "Detail: $INSTALL_SH is missing or not executable."
    exit 90
}

# Sandbox for the run. trap guarantees cleanup even on failure.
TEST_HOME=$(mktemp -d -t dotfiles-install-test.XXXXXX) || {
    echo "[FAIL] install.sh behavior"
    echo "Suggested fix: verify that mktemp works and \$TMPDIR is writable."
    echo "Detail: mktemp failed to create a sandbox directory."
    exit 90
}
trap 'rm -rf "$TEST_HOME"' EXIT

# ─── Validation helpers ───────────────────────────────────────────────────────
fail() {
    # fail <detail>
    echo "[FAIL] install.sh behavior"
    echo "Suggested fix: inspect install.sh (link function, symlink targets, backup logic) against the expected behavior reported below."
    echo "Detail: $1"
    exit 1
}

# Counts .bak.* files inside $TEST_HOME (top-level and .config/).
count_backups() {
    find "$TEST_HOME" "$TEST_HOME/.config" -maxdepth 1 -name '*.bak.*' 2>/dev/null | wc -l | tr -d ' '
}

# ─── Pre-existing file seeding ────────────────────────────────────────────────
# Three destinations pre-exist as regular files with a marker content.
# The other two (starship.toml, .editorconfig) are left absent to cover
# both branches of the link() if.
echo "# marker-zshrc-preexisting"     > "$TEST_HOME/.zshrc"
echo "# marker-zshenv-preexisting"    > "$TEST_HOME/.zshenv"
echo "# marker-gitconfig-preexisting" > "$TEST_HOME/.gitconfig"

# ─── First run ────────────────────────────────────────────────────────────────
if ! first_output=$(HOME="$TEST_HOME" "$INSTALL_SH" 2>&1); then
    fail "first run of install.sh exited non-zero. Output:
$first_output"
fi

# Validate the five symlinks. Each entry: "<path relative to $TEST_HOME>|<expected source relative to $REPO>".
targets=(
    ".zshrc|.zshrc"
    ".zshenv|.zshenv"
    ".config/starship.toml|config/starship.toml"
    ".editorconfig|config/editorconfig"
    ".gitconfig|config/gitconfig"
)

for entry in "${targets[@]}"; do
    dst_rel="${entry%%|*}"
    src_rel="${entry##*|}"
    dst="$TEST_HOME/$dst_rel"
    expected="$REPO/$src_rel"

    [[ -L "$dst" ]] || fail "expected symlink at $dst_rel, but it is missing or not a symlink."
    actual=$(readlink "$dst")
    [[ "$actual" == "$expected" ]] || fail "symlink $dst_rel points to '$actual', expected '$expected'."
done

# Validate backup of the three pre-existing destinations.
preexisted=(".zshrc" ".zshenv" ".gitconfig")
for name in "${preexisted[@]}"; do
    shopt -s nullglob
    matches=("$TEST_HOME/$name".bak.*)
    shopt -u nullglob
    (( ${#matches[@]} >= 1 )) || fail "expected a .bak.* backup for $name, none found."

    # Verify that the original marker content is preserved in some backup.
    found_marker=false
    for bak in "${matches[@]}"; do
        if grep -q "marker-${name#.}-preexisting" "$bak" 2>/dev/null; then
            found_marker=true
            break
        fi
    done
    $found_marker || fail "no backup of $name preserves the original marker content."
done

# The two destinations with no pre-existing file must not generate a backup.
for name in ".editorconfig" ".config/starship.toml"; do
    shopt -s nullglob
    matches=("$TEST_HOME/$name".bak.*)
    shopt -u nullglob
    (( ${#matches[@]} == 0 )) || fail "unexpected backup created for non-preexisting destination $name."
done

# ~/.gitconfig.local must be created with the stub content.
gitlocal="$TEST_HOME/.gitconfig.local"
[[ -f "$gitlocal" ]] || fail ".gitconfig.local was not created."
head -n1 "$gitlocal" | grep -q "~/.gitconfig.local" || fail ".gitconfig.local does not start with the expected stub header."

# ─── Idempotency ──────────────────────────────────────────────────────────────
backups_before=$(count_backups)

if ! second_output=$(HOME="$TEST_HOME" "$INSTALL_SH" 2>&1); then
    fail "second run of install.sh (idempotency) exited non-zero. Output:
$second_output"
fi

backups_after=$(count_backups)
[[ "$backups_before" == "$backups_after" ]] || fail "second run created new backups ($backups_before → $backups_after); install.sh is not idempotent."

# All five destinations must be reported as [ok] on the second run.
ok_count=$(echo "$second_output" | grep -c '^\[ok\]')
(( ok_count >= 5 )) || fail "second run reported $ok_count '[ok]' lines, expected at least 5 (one per symlink)."

# ─── OK ───────────────────────────────────────────────────────────────────────
echo "[OK] install.sh behavior"
exit 0
