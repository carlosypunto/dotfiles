# ─── Docker CLI completions ───────────────────────────────────────────────────
# Adds Docker completions to fpath before initializing compinit
[ -d "$HOME/.docker/completions" ] && fpath=($HOME/.docker/completions $fpath)

# ─── Cargo (rustc sysroot) ────────────────────────────────────────────────────
# _cargo ends with a self-invocation and must be autoloaded by compinit, not sourced.
# Adding the sysroot to fpath lets compinit manage it in the correct context.
# $RUSTC_SYSROOT is cached in exports.zsh (avoids relaunching rustc here)
[ -n "$RUSTC_SYSROOT" ] && fpath+=("$RUSTC_SYSROOT/share/zsh/site-functions")

# ─── zstyle ───────────────────────────────────────────────────────────────────
# Must be configured before compinit to take effect from the start.
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
zstyle ':completion:*' menu select                              # arrow-key navigation in the menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # case-insensitive matching
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}           # same colors as eza/ls
zstyle ':completion:*' special-dirs true                        # complete . and .. in cd
zstyle ':completion:*' use-cache on                             # cache expensive results (kubectl, SSH…)
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"

# ─── compinit ─────────────────────────────────────────────────────────────────
# Initializes zsh's autocompletion system.
# Must run AFTER modifying fpath and BEFORE any completion is used.
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# ─── Completion cache helper ──────────────────────────────────────────────────
# Generates and caches the completion script for a command. Regenerated only when
# the binary is newer than the cache file (same strategy as brew/starship).
# Usage: _cache_completion <name> <cmd> [args...]
function _cache_completion() {
    local name="$1" cmd="$2"; shift 2
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/${name}_completion.zsh"
    # Capture the binary path once: if it doesn't exist, return; if it does,
    # reuse it in the freshness check without relaunching `command -v`.
    local bin
    bin=$(command -v "$cmd") || return
    if [[ ! -f "$cache" || "$bin" -nt "$cache" ]]; then
        # Write to a temp file and move atomically only if the command succeeded
        # and produced non-empty output. Without this, a transient binary failure
        # would leave an empty cache that gets reused until the next binary update
        # (invisible broken state).
        # The cache directory is created by .zshrc, not duplicated here.
        local tmp="${cache}.tmp.$$"
        if "$cmd" "$@" > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
            mv "$tmp" "$cache"
        else
            rm -f "$tmp"
            return 1
        fi
    fi
    source "$cache"
}

# ─── Completions (rustup, kubectl, swiftly, pnpm, gh, starship) ──────────────
_cache_completion rustup   rustup   completions zsh
_cache_completion kubectl  kubectl  completion  zsh
_cache_completion swiftly  swiftly  completions zsh
_cache_completion pnpm     pnpm     completion  zsh
_cache_completion gh       gh       completion -s zsh
_cache_completion starship starship completions zsh

unset -f _cache_completion
