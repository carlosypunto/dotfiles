# Brewfile — dependencies installable via Homebrew for this dotfiles environment.
#
# Bootstrap from scratch:
#   brew bundle --file="$HOME/.dotfiles/Brewfile"
#
# Idempotent: brew bundle only installs what is missing.
# To check for differences without installing: brew bundle check --verbose

# ─── Shell base ───────────────────────────────────────────────────────────────
brew "starship"                  # prompt; config in config/starship.toml
brew "zsh-syntax-highlighting"   # plugin loaded at the end of .zshrc

# ─── Terminal utilities ───────────────────────────────────────────────────────
brew "anomalyco/tap/opencode"    # agente de coding AI que corre en terminal
brew "bat"                       # cat with syntax highlighting and git integration
brew "eza"                       # modern ls with git status (aliases ls/ll/la use it if installed)
brew "exiftool"                  # read and write EXIF metadata
brew "htop"                      # interactive process viewer
brew "jq"                        # JSON CLI (preferred by the json() function)
brew "ncdu"                      # disk usage in NCurses
brew "tlrc"                      # official tldr client
brew "tree"                      # directory tree (used by tre())
brew "wget"                      # file downloader

# ─── Compression (targz function) ────────────────────────────────────────────
brew "pigz"                      # parallel gzip on multi-core

# ─── Git ─────────────────────────────────────────────────────────────────────
brew "git-lfs"                   # Git Large File Storage (configured in config/gitconfig)
brew "git-town"                  # high-level CLI for git workflows
brew "ejoffe/tap/spr"            # stacked pull requests on GitHub
brew "withgraphite/tap/graphite" # stacked PRs and review on GitHub

# ─── Language version managers ───────────────────────────────────────────────
brew "rbenv"                     # Ruby; lazy-loaded in tools.zsh
brew "nvm"                       # Node; lazy-loaded in tools.zsh
brew "pyenv"                     # Python; init cached in tools.zsh

# ─── JavaScript / Node ───────────────────────────────────────────────────────
brew "pnpm"                      # preferred package manager over npm
brew "yarn"                      # alternative package manager

# ─── Python ──────────────────────────────────────────────────────────────────
brew "uv"                        # ultrafast Python package installer and resolver

# ─── iOS / macOS — dependencies and tooling ──────────────────────────────────
brew "cocoapods"                 # Cocoa dependency manager
brew "carthage"                  # decentralized Cocoa dependency manager
brew "xcode-build-server"        # integrates Xcode with sourcekit-lsp
brew "swift-format"              # official Swift formatter
brew "swiftformat"               # alternative Swift formatter
brew "swiftlint"                 # Swift style linter
brew "xcbeautify"                # xcodebuild output beautifier
brew "xcodegen"                  # generates .xcodeproj from spec and folder structure
brew "xcresultparser"            # parses .xcresult from builds and tests

# ─── Swift server-side ───────────────────────────────────────────────────────
brew "vapor"                     # Vapor CLI (Swift web framework)

# ─── Cloud / remote dev ──────────────────────────────────────────────────────
brew "kubectl"                   # Kubernetes CLI; alias k= and cached completions
brew "gh"                        # GitHub CLI; cached completions

# ─── Scripting / lint ────────────────────────────────────────────────────────
brew "shellcheck"                # static linter for bash/sh scripts
brew "cmake"                     # cross-platform build system
brew "cmark"                     # Markdown implementation (CommonMark)

# ─── System libraries ────────────────────────────────────────────────────────
brew "gdbm"                      # GNU database manager
brew "libffi"                    # portable Foreign Function Interface
brew "zlib"                      # general-purpose lossless compression

# ─── GUI apps ────────────────────────────────────────────────────────────────
cask "codex"                     # OpenAI's coding agent running in the terminal
cask "kitty"                     # terminal with integration in tools.zsh
cask "zed"                       # editor; $EDITOR / $VISUAL point here
cask "sublime-text"              # used by the s() function
cask "mactex"                    # full TeX Live distribution with GUI apps
cask "postgres-app"              # Postgres app wrapper
cask "kaleidoscope"              # diff/merge tool
cask "tower"                     # Git client
cask "tuist"                     # Xcode project management at scale
cask "lm-studio"                 # LM Studio, run LLMs locally
cask "sloth"                     # shows all open files and sockets currently in use

# ─── GUI apps with volatile cask name — verify before uncommenting ────────────
# cask "docker-desktop"            # Docker Desktop (renamed in some versions)

# ─── Manual installations (not available via brew) ───────────────────────────
# Swiftly:     curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
# Flutter:     https://docs.flutter.dev/get-started/install/macos    → ~/FlutterSDK/flutter
# Android SDK: https://developer.android.com/studio                  → ~/Library/Android/sdk
# Rust:        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
