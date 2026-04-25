#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Creates a symlink src→dst. If dst already points to the correct source, skips it.
# If dst exists (regular file or another symlink), backs it up before replacing.
link() {
    local rel="$1"
    local dst="$2"
    local src="$DOTFILES/$rel"

    if [[ "$(readlink "$dst" 2>/dev/null)" == "$src" ]]; then
        echo "[ok]      $dst"
        return
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
        # Split declaration and assignment: `local backup=$(...)` masks the
        # exit code of date(1); separating them preserves it for set -e.
        local backup
        backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dst" "$backup"
        echo "[backup]  $backup"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "[linked]  $dst"
    echo "       →  $src"
}

echo ""
echo "Installing dotfiles from $DOTFILES"
echo "────────────────────────────────────────"

# Warning if this clone is not at the recommended canonical location.
# ~/.dotfiles remains the suggested location but is not a hard requirement:
# the active root is the clone from which install.sh is executed and symlinks
# point to that tree. Nothing is moved, copied or relocated automatically.
if [[ "$DOTFILES" != "$HOME/.dotfiles" ]]; then
    echo "Warning: this repository is not located at ~/.dotfiles."
    echo "Install will continue using the current clone: $DOTFILES"
    echo "If you want the canonical location, move it first: mv \"$DOTFILES\" ~/.dotfiles"
    echo ""
fi

link ".zshrc"                "$HOME/.zshrc"
link ".zshenv"               "$HOME/.zshenv"
link "config/starship.toml"  "$HOME/.config/starship.toml"
link "config/editorconfig"   "$HOME/.editorconfig"
link "config/gitconfig"      "$HOME/.gitconfig"

# Creates ~/.gitconfig.local with a stub if it does not exist.
# Included by config/gitconfig via [include] at the end of the file.
# Use it for machine-specific overrides (identity, signing, etc.) without
# committing them to the repository.
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    cat > "$HOME/.gitconfig.local" <<'EOF'
# ~/.gitconfig.local — machine-specific overrides.
# This file is NOT versioned. Included by config/gitconfig via [include].
# Uncomment and adjust the blocks you need.

# ─── Identity ─────────────────────────────────────────────────
# Useful when this machine is for work and the global identity is personal.
# [user]
#     name  = Full Name
#     email = work@company.com

# ─── Commit signing with SSH key ──────────────────────────────
# Requires git >= 2.34 and openssh >= 8.0. config/gitconfig already sets gpg.format = ssh.
# [user]
#     signingkey = ~/.ssh/id_ed25519.pub
# [commit]
#     gpgsign = true
# [tag]
#     gpgsign = true

# ─── URL rewrite to force SSH over HTTPS ──────────────────────
# Useful if you clone with HTTPS but want to push with SSH (no tokens).
# [url "git@github.com:"]
#     insteadOf = https://github.com/

# ─── Conditional identity per directory ───────────────────────
# Applies a different config in repos under ~/work/ (which will live in
# ~/.gitconfig.work, also not versioned).
# [includeIf "gitdir:~/work/"]
#     path = ~/.gitconfig.work
EOF
    echo "[created] $HOME/.gitconfig.local"
else
    echo "[ok]      $HOME/.gitconfig.local"
fi

echo "────────────────────────────────────────"

# Count of backups created by previous runs. Does not delete them — just warns.
# Pattern: <destination>.bak.YYYYMMDDHHMMSS (see the link function above).
backup_count=$(find "$HOME" "$HOME/.config" -maxdepth 1 -name '*.bak.*' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$backup_count" -gt 0 ]]; then
    echo "Notice: $backup_count backup file(s) from previous runs."
    echo "       Inspect: find \"\$HOME\" \"\$HOME/.config\" -maxdepth 1 -name '*.bak.*'"
    echo "       Delete:  same command + -delete (review with -print first)."
    echo ""
fi

# Post-install Brewfile diagnostic via the helper shared with test.sh.
# Not a gate: any result is treated as informational/warning; the basic symlink
# installation is already complete. The helper classifies host failure (brew
# missing, permissions, etc.) vs repo failure (invalid Brewfile).
BREWFILE_HELPER="$DOTFILES/scripts/check-brewfile.sh"
if [[ -x "$BREWFILE_HELPER" ]]; then
    if helper_output=$("$BREWFILE_HELPER" "$DOTFILES/Brewfile" 2>&1); then
        echo "To install all dependencies declared in the Brewfile:"
        echo "  brew bundle --file=\"$DOTFILES/Brewfile\""
        echo ""
    else
        echo "Warning: Brewfile diagnostics reported an issue."
        echo "$helper_output"
        echo ""
    fi
else
    echo "Warning: Brewfile diagnostics are unavailable because scripts/check-brewfile.sh is missing or not executable."
    echo "Suggested fix: restore the helper script permissions or repository contents, then rerun ./test.sh."
    echo ""
fi

echo "Done. Run 'source ~/.zshrc' to activate the changes."
echo ""
