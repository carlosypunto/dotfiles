# Copies the default SSH public key to the clipboard.
# Useful for quickly pasting it into GitHub, servers, etc.
# Prefers id_ed25519 over id_rsa: ed25519 is currently recommended as it is
# more secure and produces shorter keys than RSA.
# Usage: sshpubkey
function sshpubkey() {
    local key;
    if [[ -f ~/.ssh/id_ed25519.pub ]]; then
        key=~/.ssh/id_ed25519.pub;
    elif [[ -f ~/.ssh/id_rsa.pub ]]; then
        key=~/.ssh/id_rsa.pub;
    else
        echo "No public key found in ~/.ssh/";
        return 1;
    fi;
    pbcopy < "$key";
    echo "Key copied to clipboard: $key";
}
