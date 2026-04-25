# Clones a git repository and automatically enters the created directory.
# Avoids having to do `git clone` and then `cd` separately.
# Handles flags before the URL (e.g. --depth, --branch) by scanning all
# arguments to find the URL (first non-flag arg) and optional directory (second).
# Usage: gclone https://github.com/user/repo.git
#        gclone --depth 1 https://github.com/user/repo.git
#        gclone https://github.com/user/repo.git my-dir
function gclone() {
    local url="" dir="" a found_url=0
    for a in "$@"; do
        if [[ "$a" != -* ]]; then
            if (( !found_url )); then
                url="$a"
                found_url=1
            else
                dir="$a"
                break
            fi
        fi
    done
    dir="${dir:-$(basename "${url%.git}")}"
    git clone "$@" && cd "$dir"
}
