# ─── Kitty (terminal integration) ─────────────────────────────────────────────
# Only activated if the shell is running inside Kitty
if test -n "$KITTY_INSTALLATION_DIR"; then
    export KITTY_SHELL_INTEGRATION="enabled"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
fi

# ─── Homebrew ─────────────────────────────────────────────────────────────────
# brew shellenv costs ~100ms; cached to disk and regenerated only when the
# brew binary is newer than the cache file (i.e., after a Homebrew update).
# $BREW_BIN was detected in exports.zsh (Apple Silicon vs Intel); if unset,
# Homebrew is not installed on this machine and the entire block is skipped.
if [ -n "$BREW_BIN" ]; then
    _brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/brew_shellenv.zsh"
    if [[ ! -f "$_brew_cache" || $BREW_BIN -nt "$_brew_cache" ]]; then
        $BREW_BIN shellenv > "$_brew_cache"
    fi
    source "$_brew_cache"
    unset _brew_cache
fi

# ─── rbenv (Ruby version manager) ─────────────────────────────────────────────
# rbenv adds ~100ms to startup with `eval "$(rbenv init -)"`.
# Uses the same lazy pattern as nvm: stubs for the most common commands that
# load rbenv on first invocation and then remove themselves with `unfunction`.
# The `command -v` guard avoids defining stubs with no real rbenv behind them,
# consistent with the pyenv block below.
if command -v rbenv &>/dev/null; then
    function _load_rbenv() {
        unset -f _load_rbenv
        eval "$(rbenv init -)"
    }

    function rbenv()  { unfunction rbenv ruby gem bundle irb; _load_rbenv; rbenv "$@"; }
    function ruby()   { unfunction rbenv ruby gem bundle irb; _load_rbenv; ruby "$@"; }
    function gem()    { unfunction rbenv ruby gem bundle irb; _load_rbenv; gem "$@"; }
    function bundle() { unfunction rbenv ruby gem bundle irb; _load_rbenv; bundle "$@"; }
    function irb()    { unfunction rbenv ruby gem bundle irb; _load_rbenv; irb "$@"; }
fi

# ─── pyenv (Python version manager) ───────────────────────────────────────────
# pyenv init - zsh (~50ms) adds shims to PATH and configures autocompletion.
# Cached to disk the same way as brew shellenv and starship init.
if command -v pyenv &>/dev/null; then
    _pyenv_bin=$(command -v pyenv)
    _pyenv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/pyenv_init.zsh"
    if [[ ! -f "$_pyenv_cache" || "$_pyenv_bin" -nt "$_pyenv_cache" ]]; then
        pyenv init - zsh > "$_pyenv_cache"
    fi
    source "$_pyenv_cache"
    unset _pyenv_cache _pyenv_bin
fi

# ─── Starship (prompt) ────────────────────────────────────────────────────────
# Starship is a minimal, fast prompt with no framework dependency.
# Shows contextual information (git branch, language version, etc.) only when
# relevant. Requires prior installation: brew install starship.
# Config lives in ~/.config/starship.toml.
# starship init zsh (~20-50ms) is cached to disk like brew shellenv. The binary
# path is captured in $_starship_bin to avoid relaunching `command -v` in the
# freshness check.
if command -v starship &>/dev/null; then
    _starship_bin=$(command -v starship)
    _starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship_init.zsh"
    if [[ ! -f "$_starship_cache" || "$_starship_bin" -nt "$_starship_cache" ]]; then
        starship init zsh > "$_starship_cache"
    fi
    source "$_starship_cache"
    unset _starship_cache _starship_bin
fi

# ─── Swiftly (Swift toolchain manager) ────────────────────────────────────────
# Loads the Swiftly environment if installed. Configures the active toolchain
# so that `swift`, `swiftc` and other tools point to the correct version.
# Only runs if the env file exists (requires prior Swiftly installation).
[ -f "$SWIFTLY_HOME/env.sh" ] && source "$SWIFTLY_HOME/env.sh"

# ─── nvm (Node version manager) ───────────────────────────────────────────────
# nvm adds ~200-500ms to shell startup even when Node is not used in that session.
# To avoid this, lazy loading is used: stubs are defined for `nvm`, `node`, `npm`
# and `npx` that load nvm on first invocation. Once loaded, the stubs remove
# themselves with `unfunction` and the real commands take over.
function _load_npm_completion() {
    add-zsh-hook -d precmd _load_npm_completion
    command -v npm &>/dev/null && source <(npm completion)
}

function _load_nvm() {
    unset -f _load_nvm
    # nvm may be installed via curl (→ $NVM_DIR/nvm.sh) or via brew
    # (→ $HOMEBREW_PREFIX/opt/nvm/nvm.sh). curl is tried first as it is the
    # default installation; brew is the fallback.
    local _nvm_sh="$NVM_DIR/nvm.sh"
    [ -s "$_nvm_sh" ] || _nvm_sh="${HOMEBREW_PREFIX}/opt/nvm/nvm.sh"
    [ -s "$_nvm_sh" ] && \. "$_nvm_sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _load_npm_completion
}

# pnpm is the preferred Node package manager over npm in this environment.
# npm is still available via these stubs (lazy nvm load), but pnpm is recommended.
function nvm()  { unfunction nvm node npm npx; _load_nvm; nvm "$@"; }
function node() { unfunction nvm node npm npx; _load_nvm; node "$@"; }
function npm()  { unfunction nvm node npm npx; _load_nvm; npm "$@"; }
function npx()  { unfunction nvm node npm npx; _load_nvm; npx "$@"; }
