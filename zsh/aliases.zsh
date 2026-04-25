# ─── Navigation and listing ───────────────────────────────────────────────────
# bat as a cat replacement: syntax highlighting, line numbers and git diff.
# Automatically detects pipes and omits decorations — safe to alias over cat.
if command -v bat &>/dev/null; then
    alias cat='bat'
fi

# Use eza if installed (brew install eza): colors, modern dates and git status.
# Falls back to BSD ls with -G flag (color on macOS).
if command -v eza &>/dev/null; then
    alias ls='eza'
    alias ll='eza -lA --git'    # long listing with hidden files and git status
    alias la='eza -A'           # short listing with hidden files
else
    alias ls='ls -G'            # colorize output (BSD flag for macOS)
    alias ll='ls -lAG'          # long listing with hidden files and color
    alias la='ls -AG'           # short listing with hidden files and color
fi

# ─── Git ──────────────────────────────────────────────────────────────────────
# Shortcuts for the most repetitive git commands in day-to-day work.
# Single- or two-letter names for maximum typing speed.
alias gs='git status'           # working tree and staging area status
alias ga='git add'              # add files to the staging area
alias gc='git commit -v'        # create a commit showing the diff in the editor
alias gcm='git commit -m'       # quick commit without opening the editor
alias gca='git commit --amend --no-edit'  # amend without touching the message
alias gp='git push'             # push commits to remote
alias gpl='git pull'            # fetch and merge changes from remote
alias gco='git checkout'        # switch branch or restore files
alias gb='git branch'           # list, create or delete branches
alias gd='git diff'             # diff of working tree against staging area
alias gds='git diff --staged'   # diff of staging area against last commit
alias gsw='git switch'          # switch branch (safer than gco for this purpose)
alias gcb='git switch -c'       # create a new branch and switch to it
alias gst='git stash'           # save changes to the stash
alias gstp='git stash pop'      # restore the last stash and remove it from the stack
alias gsta='git stash apply'    # restore the last stash without removing it
alias gl='git log --oneline --graph --decorate -20'  # compact graph history

# ─── Docker ───────────────────────────────────────────────────────────────────
# Shortcuts for inspecting containers and images and working with Docker Compose.
alias dps='docker ps'           # list running containers
alias dpsa='docker ps -a'       # list all containers (including stopped)
alias di='docker images'        # list local images
alias dc='docker compose'       # quick access to Docker Compose (v2)

# ─── Flutter ──────────────────────────────────────────────────────────────────
# Flutter commands are long; these shortcuts cover the typical development cycle.
alias fp='flutter pub get'      # install/update dependencies from pubspec.yaml
alias fr='flutter run'          # start the app on the connected device or simulator
alias ft='flutter test'         # run the project test suite
alias fb='flutter build'        # build the app (accepts subcommands: ios, apk, appbundle…)

# ─── Xcode / iOS ──────────────────────────────────────────────────────────────
alias sim='open -a Simulator'   # open Xcode's Simulator.app without going through the Dock
alias xcc='xcodebuild clean'    # clean build artifacts of the active project
alias xp='xed .'                # open the Xcode project in the current directory

# ─── kubectl ──────────────────────────────────────────────────────────────────
# kubectl is the most-typed command in any Kubernetes workflow;
# `k` as the root alias is a universal community convention.
alias k='kubectl'                                               # root alias
alias kgp='kubectl get pods'                                    # list pods in the active namespace
alias kgs='kubectl get services'                                # list services in the active namespace
alias kns='kubectl config set-context --current --namespace'    # change active namespace: kns my-ns

# ─── Rust ─────────────────────────────────────────────────────────────────────
alias cb='cargo build'          # build the Rust project
alias ct='cargo test'           # run the project tests
alias cr='cargo run'            # build and run the binary
