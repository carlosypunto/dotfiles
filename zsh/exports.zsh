# ─── Editor ───────────────────────────────────────────────────────────────────
# Zed as the default editor; --wait blocks until the file is closed.
# Checks for Zed.app presence (not `command -v zed`) because exports.zsh runs
# before brew shellenv adds /opt/homebrew/bin to PATH — `command -v` would fail
# even if Zed were installed via brew cask.
# Falls back to vim/vi so that git, crontab, etc. don't fail on machines without Zed.
if [ -d /Applications/Zed.app ]; then
    export EDITOR="zed --wait"
elif command -v vim &>/dev/null; then
    export EDITOR="vim"
else
    export EDITOR="vi"
fi
export VISUAL="$EDITOR"

# ─── Homebrew detection ───────────────────────────────────────────────────────
# brew is not yet in PATH (tools.zsh adds it via shellenv). Detect the binary
# by architecture: /opt/homebrew on Apple Silicon, /usr/local on Intel.
# BREW_BIN is reused below and in tools.zsh to avoid hardcoding the path.
if [ -x /opt/homebrew/bin/brew ]; then
    BREW_BIN=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
    BREW_BIN=/usr/local/bin/brew
fi

# ─── Xcode / Apple SDK ────────────────────────────────────────────────────────
# Points to the active Xcode SDK; required for compiling native extensions.
# xcrun --show-sdk-path costs ~50-200ms; cached to disk like brew shellenv.
# Invalidation: regenerated when the xcrun binary changes (CLT/Xcode updates).
# If the active Xcode is changed with `xcode-select -s`, delete
# ~/.cache/xcode_sdkroot manually to force regeneration.
if command -v xcrun &>/dev/null && [[ -z "$SDKROOT" ]]; then
    _sdkroot_cache="${XDG_CACHE_HOME:-$HOME/.cache}/xcode_sdkroot"
    _xcrun_bin=$(command -v xcrun)
    if [[ ! -f "$_sdkroot_cache" || "$_xcrun_bin" -nt "$_sdkroot_cache" ]]; then
        _sdk=$(xcrun --show-sdk-path 2>/dev/null)
        [[ -n "$_sdk" ]] && printf '%s\n' "$_sdk" > "$_sdkroot_cache"
        unset _sdk
    fi
    [[ -f "$_sdkroot_cache" ]] && export SDKROOT=$(< "$_sdkroot_cache")
    unset _sdkroot_cache _xcrun_bin
fi

# ─── Native compilation (readline and openssl via Homebrew) ───────────────────
# These variables are needed by tools like Ruby, Python or any gem/pip that
# compiles C extensions against readline or openssl.
# brew --prefix costs ~50ms per call; results are cached to disk using the
# same pattern as brew shellenv: regenerated only when the brew binary is newer
# than the cache file (i.e., after a Homebrew update).
# The entire block is skipped if Homebrew is not installed.
if [ -n "$BREW_BIN" ]; then
    _brew_prefix_cache="${XDG_CACHE_HOME:-$HOME/.cache}/brew_prefixes.zsh"
    if [[ ! -f "$_brew_prefix_cache" || "$BREW_BIN" -nt "$_brew_prefix_cache" ]]; then
        {
            printf 'READLINE_PATH=%q\n' "$($BREW_BIN --prefix readline 2>/dev/null)"
            printf 'OPENSSL_PATH=%q\n'  "$($BREW_BIN --prefix openssl  2>/dev/null)"
        } > "$_brew_prefix_cache"
    fi
    source "$_brew_prefix_cache"
    unset _brew_prefix_cache

    export LDFLAGS="${LDFLAGS:+$LDFLAGS }-L$READLINE_PATH/lib -L$OPENSSL_PATH/lib"
    export CPPFLAGS="${CPPFLAGS:+$CPPFLAGS }-I$READLINE_PATH/include -I$OPENSSL_PATH/include"
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+$PKG_CONFIG_PATH:}$READLINE_PATH/lib/pkgconfig:$OPENSSL_PATH/lib/pkgconfig"

    # Tells rbenv which openssl to use when compiling a Ruby version
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$OPENSSL_PATH"
fi

# ─── Flutter ──────────────────────────────────────────────────────────────────
export FLUTTER_SDK_ROOT=~/FlutterSDK/flutter

# ─── Android SDK ──────────────────────────────────────────────────────────────
export ANDROID_SDK_ROOT=~/Library/Android/sdk

# ─── Swift (Swiftly) ──────────────────────────────────────────────────────────
# Swiftly is the official Swift toolchain manager (equivalent to rustup).
# Installs and manages Swift versions independently of Xcode.
export SWIFTLY_HOME="$HOME/.swiftly"

# ─── Node (nvm and pnpm) ──────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/Library/pnpm"

# ─── Python (pyenv) ───────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"

# ─── LM Studio ────────────────────────────────────────────────────────────────
export LMSTUDIO_HOME="$HOME/.lmstudio"

# ─── Rust (cargo sysroot) ─────────────────────────────────────────────────────
# rustc --print sysroot costs ~50ms; cached to disk like brew shellenv.
# Invalidation: regenerated when the rustc binary changes (each rustup update).
# Used in completions.zsh to add _cargo to fpath without relaunching rustc.
if command -v rustc &>/dev/null; then
    _rustc_bin=$(command -v rustc)
    _rustc_cache="${XDG_CACHE_HOME:-$HOME/.cache}/rustc_sysroot"
    if [[ ! -f "$_rustc_cache" || "$_rustc_bin" -nt "$_rustc_cache" ]]; then
        rustc --print sysroot > "$_rustc_cache" 2>/dev/null
    fi
    [[ -f "$_rustc_cache" ]] && export RUSTC_SYSROOT=$(< "$_rustc_cache")
    unset _rustc_bin _rustc_cache
fi

# ─── zsh history ──────────────────────────────────────────────────────────────
# Without this configuration zsh uses very limited defaults (~30 entries).
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
