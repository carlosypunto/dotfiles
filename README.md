# Dotfiles

Personal, opinionated zsh configuration for macOS with a focus on iOS/Swift development. Vanilla zsh with no external frameworks — everything here works with standard zsh. Everything lives in `~/.dotfiles` and is activated via symlinks from `$HOME`.

## Structure

```
.dotfiles/
├── install.sh                # creates all symlinks at once
├── Brewfile                  # dependencies installable via Homebrew (brew bundle)
├── test.sh                   # smoke test: syntax, module loading, Brewfile and anti-drift
├── config/
│   └── starship.toml         # → ~/.config/starship.toml
├── .zshenv                   # → ~/.zshenv (non-interactive shells)
├── .zshrc                    # → ~/.zshrc  (main orchestrator)
├── docs/
│   ├── setup.md              # Expected environment and installation flow from scratch
│   ├── swift.md              # Swift toolchain management (Swiftly vs Xcode)
│   ├── conventions.md        # How to add new content to the repo
│   └── reference.md          # Complete reference of aliases, functions and completions
├── scripts/
│   ├── check-brewfile.sh     # Non-destructive Brewfile diagnostics (host vs repo)
│   └── check-docs-drift.sh   # Anti-drift between implementation and docs/reference.md
├── .github/
│   └── workflows/ci.yml      # Minimal CI on macos-latest (smoke test without Homebrew)
└── zsh/
    ├── exports.zsh           # Environment variables and compilation flags
    ├── path.zsh              # $PATH construction in precedence order
    ├── tools.zsh             # Tool initialization (Homebrew, rbenv, nvm, Kitty)
    ├── aliases.zsh           # Shell aliases organized by domain
    ├── completions.zsh       # fpath, compinit and completions by tool
    └── functions/
        ├── general.zsh       # Generic terminal utilities
        ├── git.zsh           # Git functions
        ├── docker.zsh        # Docker functions
        ├── ios.zsh           # Xcode and iOS functions
        ├── flutter.zsh       # Flutter functions
        ├── postgres.zsh      # PostgreSQL functions
        └── ssh.zsh           # SSH functions
```

## Installation

> Requires macOS with Homebrew installed. For a completely new machine, see [docs/setup.md](docs/setup.md).

```zsh
cd ~/.dotfiles
./install.sh                   # creates the symlinks
brew bundle --file=Brewfile    # installs all declared dependencies
source ~/.zshrc
./test.sh                      # verifies everything loads correctly
```

`install.sh` is idempotent: it backs up with a timestamp if the destination already exists.

`brew bundle` is also idempotent — it only installs what's missing.

Some casks (Docker, Postgres.app, Kaleidoscope) are commented in the `Brewfile` due to volatile names. Review and uncomment them if needed.

## Validation

`./test.sh` is the only entry point to validate the working tree. It runs eight checks:

1. Bash syntax of `install.sh`
2. Zsh syntax of all modules  
3. Chained loading in `.zshrc` order
4. Loading with `zprof` active
5. Non-destructive Brewfile validation (delegated to `scripts/check-brewfile.sh`)
6. Anti-drift between implementation and `docs/reference.md` (delegated to `scripts/check-docs-drift.sh`) — keeping code and docs in sync
7. Behavioral validation of `install.sh` in a `$HOME` sandbox (delegated to `scripts/check-install.sh`)
8. Runtime validation that each documented symbol exists after loading modules (delegated to `scripts/check-runtime-symbols.sh`)

The real loading checks use a tempdir per run for `XDG_CACHE_HOME` and `TMPDIR` and don't leave residue on the host.

**Flags and overrides:**

- `SKIP_BREWFILE=1 ./test.sh` — skips check 5. Only for CI, where runners don't have your Homebrew state. Should be left undefined locally.
- `DOTFILES=/path/to/clone zsh -i` — points `.zshrc` to an alternate clone for interactive testing, with warning + fallback to `~/.dotfiles` if the path is invalid. This is a convenience shortcut, not a substitute for `./test.sh`.
- CI (`.github/workflows/ci.yml`) runs `./test.sh` with `SKIP_BREWFILE=1` on `macos-latest` on every push to `main` and on every PR.

Complete details in [docs/reference.md](docs/reference.md).

## Documentation

- [Expected environment and installation](docs/setup.md)
- [Swift toolchain management](docs/swift.md)
- [How to add new content](docs/conventions.md)
- [Reference of aliases, functions and completions](docs/reference.md)
