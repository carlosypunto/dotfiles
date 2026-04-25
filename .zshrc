# ─── Startup profiler (zprof) ─────────────────────────────────────────────────
# Measures the time each function takes during shell startup.
# Useful for identifying which part of the rc is slowing down startup.
#
# Usage:
#   ZPROF=true zsh -i -c exit        # prints the report and exits
#   ZPROF=true zsh -i                # opens an interactive session with the report at exit
#
# Output shows each function with its total time, self time, and call count,
# sorted by descending cost.
[[ "$ZPROF" = true ]] && zmodload zsh/zprof

# Path to the dotfiles repository. Defaults to ~/.dotfiles (canonical location).
# Exporting DOTFILES before starting the shell points it to an alternative clone
# for interactive testing (ergonomic aid, not a substitute for ./test.sh).
# Minimal override validation: directory must exist and contain a readable .zshrc
# and .zshenv. On failure, warns and falls back to ~/.dotfiles. No auto-detection
# or automatic path searching; the choice is always explicit.
if [[ -n "${DOTFILES:-}" && ( ! -d "$DOTFILES" || ! -r "$DOTFILES/.zshrc" || ! -r "$DOTFILES/.zshenv" ) ]]; then
    echo "Warning: DOTFILES points to an invalid repository root: $DOTFILES" >&2
    echo "Expected a readable .zshrc and .zshenv there. Falling back to ~/.dotfiles" >&2
    unset DOTFILES
fi
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# Prevents duplicate entries in PATH and fpath when reloading or opening subshells
typeset -U PATH path fpath

# Ensure the cache directory exists before module loading, so that exports.zsh
# and any subsequent module can write to it safely.
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"

# Load configuration modules in order
# Order matters: exports → path → tools → node → aliases → completions → functions
for config in \
    "$DOTFILES/zsh/exports.zsh" \
    "$DOTFILES/zsh/path.zsh" \
    "$DOTFILES/zsh/tools.zsh" \
    "$DOTFILES/zsh/node.zsh" \
    "$DOTFILES/zsh/aliases.zsh" \
    "$DOTFILES/zsh/completions.zsh"; do
    [ -f "$config" ] && source "$config"
done

# Load all function files organized by domain
for config in "$DOTFILES/zsh/functions/"*.zsh; do
    [ -f "$config" ] && source "$config"
done

# ─── Shell options ────────────────────────────────────────────────────────────
# Shell behavior — separated from exports.zsh because setopt entries are not
# environment variables: they are not exported to child processes and do not
# appear in `env`.

# Navigation
setopt AUTO_CD              # implicit cd when typing a directory name
setopt PUSHD_IGNORE_DUPS    # don't accumulate duplicates in the directory stack

# History
setopt EXTENDED_HISTORY     # save timestamp alongside each entry
setopt HIST_IGNORE_ALL_DUPS # never save duplicates even if non-consecutive
setopt HIST_IGNORE_SPACE    # don't save commands prefixed with a space
setopt HIST_REDUCE_BLANKS   # normalize whitespace before saving
setopt HIST_VERIFY          # expand !! in the prompt before executing
setopt SHARE_HISTORY        # sync history across sessions in real time
setopt HIST_FCNTL_LOCK      # OS-level lock when writing history (prevents corruption with SHARE_HISTORY)

# Line editing
# Remove / and . from WORDCHARS so Ctrl+W deletes word by word (not whole paths)
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'

# History search filtered by prefix: if text is typed, ↑/↓ only shows entries
# that start exactly with that prefix
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ─── Plugins (no framework) ───────────────────────────────────────────────────
# Installation: brew install zsh-syntax-highlighting
#
# Uses $HOMEBREW_PREFIX (defined by the brew shellenv cache in tools.zsh)
# instead of $(brew --prefix) to avoid an extra subprocess on each startup.
#
# IMPORTANT: zsh-syntax-highlighting must be loaded last — it modifies zle
# hooks and needs the rest of the environment fully initialized.
[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if [[ "$ZPROF" = true ]]; then zprof; fi
