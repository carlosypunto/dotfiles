# Opens an interactive shell (bash or sh as fallback) inside a running container.
# Useful for inspecting the internal state of a container without stopping it.
# Usage: dsh <container-name-or-id>
function dsh() {
    docker exec -it "$1" bash 2>/dev/null || docker exec -it "$1" sh;
}

# Stops all currently running Docker containers.
# Equivalent to `docker stop` on each ID returned by `docker ps -q`.
# Usage: dstop
# In zsh, $running without quotes does NOT do field splitting (SH_WORD_SPLIT off
# by default). With 2+ containers, `docker stop $running` would receive a single
# argument with embedded \n. ${=running} forces split at the point of use.
function dstop() {
    local running=$(docker ps -q);
    if [[ -n "$running" ]]; then
        docker stop ${=running};
    else
        echo "No running containers.";
    fi;
}

# Removes all stopped containers and untagged (dangling) images.
# Frees disk space without affecting active containers or tagged images.
# Usage: dclean
function dclean() {
    echo "Removing stopped containers…"
    docker container prune -f
    echo "Removing untagged images…"
    docker image prune -f
}
