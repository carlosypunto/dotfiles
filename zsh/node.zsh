# ─── Node default version (nvm) ───────────────────────────────────────────────
# Requires HOMEBREW_PREFIX (set by the brew shellenv cache in tools.zsh) as a
# fallback to locate nvm.sh in Homebrew installations. That is why this module
# is loaded after tools.zsh.
#
# nvm version default requires nvm to be loaded. It is resolved in a subshell
# once and cached; the cache is invalidated when ~/.nvm/alias/default changes.
# The subshell sources nvm.sh without affecting the parent shell or its lazy stubs.
_nvm_sh="$NVM_DIR/nvm.sh"
[[ -s "$_nvm_sh" ]] || _nvm_sh="${HOMEBREW_PREFIX}/opt/nvm/nvm.sh"
if [[ -s "$_nvm_sh" ]]; then
    _nvm_ver_cache="${XDG_CACHE_HOME:-$HOME/.cache}/nvm_default_version"
    if [[ ! -f "$_nvm_ver_cache" || "$NVM_DIR/alias/default" -nt "$_nvm_ver_cache" ]]; then
        _ver=$(source "$_nvm_sh" 2>/dev/null; nvm version default 2>/dev/null)
        [[ -n "$_ver" && "$_ver" != "N/A" ]] && echo "$_ver" > "$_nvm_ver_cache"
        unset _ver
    fi
    if [[ -f "$_nvm_ver_cache" ]]; then
        NVM_CURRENT_NODE_VERSION=$(< "$_nvm_ver_cache")
        export NVM_CURRENT_NODE_VERSION
        [ -d "$NVM_DIR/versions/node/$NVM_CURRENT_NODE_VERSION/bin" ] && \
            path=("$NVM_DIR/versions/node/$NVM_CURRENT_NODE_VERSION/bin" $path)
    fi
    unset _nvm_ver_cache
fi
unset _nvm_sh
