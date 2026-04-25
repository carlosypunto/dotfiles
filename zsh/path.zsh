# Entries are added top-to-bottom; earlier entries take higher precedence.
# General rule: local/personal tools first, SDKs next, system last.
# Uses zsh array syntax (path[] is bound to $PATH; typeset -U path in .zshrc
# guarantees no duplicates on reload).

# ─── Personal binaries ────────────────────────────────────────────────────────
path=(
    ${HOME}/.local/bin(N)
    ${HOME}/bin(N)
    $path
)

# ─── openssl (Homebrew) ───────────────────────────────────────────────────────
# Needed so the Homebrew openssl takes precedence over the system one.
# $OPENSSL_PATH is already cached in exports.zsh — don't relaunch brew --prefix
[ -d "$OPENSSL_PATH/bin" ] && path=("$OPENSSL_PATH/bin" $path)

# ─── Flutter ──────────────────────────────────────────────────────────────────
[ -d "$FLUTTER_SDK_ROOT/bin" ] && path=("$FLUTTER_SDK_ROOT/bin" $path)

# ─── Android SDK (command-line tools) ────────────────────────────────────────
[ -d "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" ] && path=("$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" $path)

# ─── Swiftly ──────────────────────────────────────────────────────────────────
# Adds the swiftly binary and the active toolchain to PATH.
# Only added if Swiftly is installed.
[ -d "$SWIFTLY_HOME/bin" ] && path=("$SWIFTLY_HOME/bin" $path)

# ─── pyenv ────────────────────────────────────────────────────────────────────
[ -d "$PYENV_ROOT/bin" ] && path=("$PYENV_ROOT/bin" $path)

# ─── Dart / Flutter pub ───────────────────────────────────────────────────────
[ -d "$HOME/.pub-cache/bin" ] && path=("$HOME/.pub-cache/bin" $path)

# ─── pnpm ─────────────────────────────────────────────────────────────────────
[ -d "$PNPM_HOME" ] && path=("$PNPM_HOME" $path)

# ─── LM Studio ────────────────────────────────────────────────────────────────
[ -d "$LMSTUDIO_HOME/bin" ] && path=("$LMSTUDIO_HOME/bin" $path)

# ─── Docker Desktop ───────────────────────────────────────────────────────────
[ -d /Applications/Docker.app/Contents/Resources/bin ] && \
    path=(/Applications/Docker.app/Contents/Resources/bin $path)

# ─── PostgreSQL (Postgres.app) ────────────────────────────────────────────────
# Detects the most recent installed version using zsh native glob with
# numeric_glob_sort, avoiding the `/bin/ls | sort -V | tail` pipeline (3 processes).
# The anonymous function gives local scope to setopt and the array, without
# polluting the shell.
() {
    setopt localoptions numeric_glob_sort
    local -a versions=(/Applications/Postgres.app/Contents/Versions/[0-9]*(N))
    (( ${#versions} )) && path=($path "${versions[-1]}/bin")
}
