# Terminal calculator with 10-digit decimal precision.
# Uses `bc` with its standard math library.
# Strips leading/trailing zeros for cleaner output.
# Usage: calc "3.5 * 2" or calc "sqrt(2)"
function calc() {
    local result="";
    result="$(printf 'scale=10;%s\n' "$*" | bc --mathlib | tr -d '\\\n')";
    #                       └─ default (when `--mathlib` is used) is 20
    #
    if [[ "$result" == *.* ]]; then
        # improve the output for decimal numbers
        printf '%s' "$result" |
        sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
            -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
            -e 's/0*$//;s/\.$//';  # remove trailing zeros
    else
        printf '%s' "$result";
    fi;
    printf "\n";
}

# Creates a directory (including intermediates) and enters it in one step.
# Usage: mkd folder/subfolder
function mkd() {
    mkdir -p "$@" && cd "${@: -1}";
}

# Navigates to the directory open in the frontmost Finder window.
# Requires macOS (uses osascript/AppleScript).
function cdf() { # short for `cdfinder`
    cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

# Packages a file or directory into .tar.gz using the fastest available compressor:
# - pigz    → parallel gzip compression (fast on multi-core)
# - gzip    → universal fallback
# Automatically excludes .DS_Store files.
# Usage: targz my_folder
function targz() {
    local tmpFile="${@%/}.tar";
    tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1;

    local size=$(stat -f"%z" "${tmpFile}");

    local cmd="";
    if hash pigz 2> /dev/null; then
        cmd="pigz";
    else
        cmd="gzip";
    fi;

    echo "Compressing .tar using \`${cmd}\`…";
    "${cmd}" -v "${tmpFile}" || return 1;
    [ -f "${tmpFile}" ] && rm "${tmpFile}";
    echo "${tmpFile}.gz created successfully.";
}

# Shows the size of a file or the total size of a directory in human-readable format.
# Without arguments shows all items in the current directory (including hidden).
# Usage: fs file_or_folder
function fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh;
    else
        local arg=-sh;
    fi
    if (( $# )); then
        du $arg -- "$@";
    else
        # (N) = null-glob: avoids "no matches found" in an empty directory
        du $arg .[^.]*(N) *(N);
    fi;
}

# git-based diff that colors differences at the word level instead of the full line
# (more readable for minor changes).
# Named gdiff to avoid overwriting the system diff (breaks in pipes and scripts).
# Only defined if git is installed.
if hash git &>/dev/null; then
    function gdiff() {
        git diff --no-index --color-words "$@";
    }
fi;

# Converts a file to a data URL (embedded base64).
# Useful for inlining images or fonts directly in HTML/CSS.
# Usage: dataurl image.png
function dataurl() {
    local mimeType=$(file -b --mime-type "$1");
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8";
    fi
    echo "data:${mimeType};base64,$(base64 -i "$1" | tr -d '\n')";
}

# Compares the original size of a file with its gzip-compressed version.
# Shows the compression ratio as a percentage.
# Usage: gz file
function gz() {
    local origsize=$(wc -c < "$1");
    local gzipsize=$(gzip -c "$1" | wc -c);
    local ratio=$(echo "$gzipsize * 100 / $origsize" | bc -l);
    printf "orig: %d bytes\n" "$origsize";
    printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio";
}

# Formats and colorizes JSON from an argument or from stdin (pipe).
# Uses jq if available (brew install jq), otherwise falls back to python3 -mjson.tool.
# Usage: json '{"foo":42}'  or  cat data.json | json
function json() {
    if command -v jq &>/dev/null; then
        if [ -t 0 ]; then
            jq . <<< "$*";
        else
            jq .;
        fi;
    elif [ -t 0 ]; then
        python3 -mjson.tool <<< "$*";
    else
        python3 -mjson.tool;
    fi;
}

# Runs `dig` showing all DNS records for a domain in human-readable format.
# Usage: digga example.com
function digga() {
    dig +nocmd "$1" any +multiline +noall +answer;
}

# Converts a string to its UTF-8 hex escape representation.
# Useful for debugging Unicode characters or building escaped strings.
# Usage: escape "café"  →  \xC3\xA9...
function escape() {
    printf "\\\x%s" $(printf '%s' "$@" | xxd -p -c1 -u);
    # print a newline unless we're piping the output to another program
    if [ -t 1 ]; then
        echo ""; # newline
    fi;
}

# Decodes Unicode escape sequences of the form \x{ABCD} to the actual character.
# Usage: unidecode "\x{1F600}"
function unidecode() {
    perl -e 'binmode(STDOUT, ":utf8"); print $ARGV[0]' -- "$@";
    if [ -t 1 ]; then
        echo "";
    fi;
}

# Returns the Unicode code point of a character in U+XXXX format.
# Usage: codepoint "é"  →  U+00E9
function codepoint() {
    perl -e 'use utf8; print sprintf("U+%04X", ord($ARGV[0]))' -- "$@";
    if [ -t 1 ]; then
        echo "";
    fi;
}

# Shows the Common Name (CN) and all Subject Alternative Names (SANs) of the
# SSL/TLS certificate for a domain, without needing a browser.
# Usage: getcertnames example.com
function getcertnames() {
    if [ -z "${1}" ]; then
        echo "ERROR: No domain specified.";
        return 1;
    fi;

    local domain="${1}";
    echo "Testing ${domain}…";
    echo ""; # newline

    local tmp=$(printf "GET / HTTP/1.0\nEOT\n" \
        | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

    if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
        local certText=$(echo "${tmp}" \
            | openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
            no_serial, no_sigdump, no_signame, no_validity, no_version");
        echo "Common Name:";
        echo ""; # newline
        echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
        echo ""; # newline
        echo "Subject Alternative Name(s):";
        echo ""; # newline
        echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
            | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
        return 0;
    else
        echo "ERROR: Certificate not found.";
        return 1;
    fi;
}

# Opens the current directory (or the given path) in Sublime Text.
# Usage: s  or  s path/to/file
function s() {
    if [ $# -eq 0 ]; then
        subl .;
    else
        subl "$@";
    fi;
}

# Opens the current directory (or the given path) in Zed.
# Usage: e  or  e path/to/file
function e() {
    if [ $# -eq 0 ]; then
        zed .;
    else
        zed "$@";
    fi;
}

# Opens the current directory (or the given path) in Vim.
# Usage: v  or  v path/to/file
function v() {
    if [ $# -eq 0 ]; then
        vim .;
    else
        vim "$@";
    fi;
}

# Opens the current directory (or the given path) with macOS `open`.
# Without arguments equivalent to opening the Finder in the current folder.
# Usage: o  or  o path/to/file
function o() {
    if [ $# -eq 0 ]; then
        open .;
    else
        open "$@";
    fi;
}

# Shows the directory tree with colors and hidden files, ignoring .git,
# node_modules and bower_components, with folders first.
# If the output fits on screen it is shown directly; otherwise paged with `less`.
# Requires the `tree` command.
# Usage: tre [path]
function tre() {
    tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX;
}

# Starts a static HTTP server in the current directory and opens the browser.
# Usage: server [port]  (defaults to 8000)
function server() {
    local port="${1:-8000}";
    sleep 1 && open "http://localhost:${port}/" &
    python3 -m http.server "${port}";
}

# Opens a man page in Preview.app (macOS) instead of the terminal.
# Generates the PDF of the man page via PostScript and opens it in Preview.
# Usage: pman ls
function pman() {
    man -t "$1" | open -f -a /Applications/Preview.app
}
