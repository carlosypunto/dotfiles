# Capabilities Reference

## Aliases

### Navigation and Listing
| Alias | Command | Description |
|---|---|---|
| `cat` | `bat` | Viewer with syntax highlighting and git diff (only if `bat` is installed) |
| `ls` | `eza` / `ls -G` | Listing with color (uses `eza` if installed, otherwise BSD `ls`) |
| `ll` | `eza -lA --git` / `ls -lAG` | Long listing with hidden files; with `eza` includes git status |
| `la` | `eza -A` / `ls -AG` | Short listing with hidden files and color |

### Git
| Alias | Command | Description |
|---|---|---|
| `gs` | `git status` | Working tree and staging area status |
| `ga` | `git add` | Add files to staging area |
| `gc` | `git commit -v` | Create a commit (shows diff in editor) |
| `gcm` | `git commit -m` | Quick commit without opening editor |
| `gca` | `git commit --amend --no-edit` | Amend last commit without touching message |
| `gp` | `git push` | Push commits to remote |
| `gpl` | `git pull` | Pull and merge changes from remote |
| `gco` | `git checkout` | Change branch or restore files |
| `gb` | `git branch` | List, create or delete branches |
| `gd` | `git diff` | Diff of working tree against staging area |
| `gds` | `git diff --staged` | Diff of staging area against last commit |
| `gsw` | `git switch` | Change branch (safer than `gco` for this) |
| `gcb` | `git switch -c` | Create and switch to new branch |
| `gst` | `git stash` | Save working tree changes to stash |
| `gstp` | `git stash pop` | Recover last stash and remove from stack |
| `gsta` | `git stash apply` | Recover last stash without removing from stack |
| `gl` | `git log --oneline --graph --decorate -20` | Compact history with branch graph (20 commits by default) |

### Docker
| Alias | Command | Description |
|---|---|---|
| `dps` | `docker ps` | List running containers |
| `dpsa` | `docker ps -a` | List all containers |
| `di` | `docker images` | List local images |
| `dc` | `docker compose` | Quick access to Docker Compose v2 |

### Flutter
| Alias | Command | Description |
|---|---|---|
| `fp` | `flutter pub get` | Install pubspec.yaml dependencies |
| `fr` | `flutter run` | Start the app on connected device |
| `ft` | `flutter test` | Run test suite |
| `fb` | `flutter build` | Build the app |

### Xcode / iOS
| Alias | Command | Description |
|---|---|---|
| `sim` | `open -a Simulator` | Open Xcode's Simulator.app |
| `xcc` | `xcodebuild clean`  | Clean build artifacts |
| `xp`  | `xed .`             | Open Xcode project in current directory |

### kubectl
| Alias | Command | Description |
|---|---|---|
| `k` | `kubectl` | Root alias |
| `kgp` | `kubectl get pods` | List pods in active namespace |
| `kgs` | `kubectl get services` | List services in active namespace |
| `kns` | `kubectl config set-context --current --namespace` | Change active namespace |

### Rust
| Alias | Command | Description |
|---|---|---|
| `cb` | `cargo build` | Build Rust project |
| `ct` | `cargo test` | Run project tests |
| `cr` | `cargo run` | Build and run binary |

---

## Functions

### General Utilities (`general.zsh`)
| Function | Usage | Description |
|---|---|---|
| `calc` | `calc "3.5 * 2"` | Calculator with 10-digit decimal precision |
| `mkd` | `mkd folder/sub` | Create directory and enter it |
| `cdf` | `cdf` | Navigate to directory open in Finder |
| `targz` | `targz my_folder` | Pack as `.tar.gz` with fastest available compressor |
| `fs` | `fs [path]` | Show size of file or directory |
| `gdiff` | `gdiff a b` | Colored word-level diff (uses git diff) |
| `dataurl` | `dataurl image.png` | Convert file to base64 data URL |
| `gz` | `gz file` | Compare original size vs gzip compressed |
| `json` | `json '{"a":1}'` | Format and colorize JSON (uses `jq` if available, else `python3`) |
| `digga` | `digga example.com` | Show all DNS records for a domain |
| `escape` | `escape "café"` | Convert text to UTF-8 hexadecimal escape sequences |
| `unidecode` | `unidecode "\x{1F600}"` | Decode Unicode escape sequences |
| `codepoint` | `codepoint "é"` | Return Unicode code point of a character |
| `getcertnames` | `getcertnames example.com` | Show CN and SANs from domain's SSL certificate |
| `s` | `s [path]` | Open in Sublime Text |
| `e` | `e [path]` | Open in Zed |
| `v` | `v [path]` | Open in Vim |
| `o` | `o [path]` | Open with macOS `open` (Finder) |
| `tre` | `tre [path]` | Directory tree with color, paginated |
| `server` | `server [port]` | Static HTTP server and open browser (default port 8000) |
| `pman` | `pman ls` | Open man page in Preview.app as PDF |

### Git (`git.zsh`)
| Function | Usage | Description |
|---|---|---|
| `gclone` | `gclone [flags] <url>` | Clone a repo and automatically enter the directory |

### Docker (`docker.zsh`)
| Function | Usage | Description |
|---|---|---|
| `dsh` | `dsh <container>` | Open interactive shell in a container |
| `dstop` | `dstop` | Stop all running containers |
| `dclean` | `dclean` | Remove stopped containers and untagged images |

### Xcode / iOS (`ios.zsh`)
| Function | Usage | Description |
|---|---|---|
| `xcclean` | `xcclean` | Delete DerivedData folder showing freed space; does nothing if not present |
| `xcopen` | `xcopen` | Open the `.xcworkspace` or `.xcodeproj` in current directory |
| `simlist` | `simlist` | List available simulators |
| `simboot` | `simboot <name>` | Boot a simulator by name (partial, case-insensitive) |
| `swift-version` | `swift-version` | Show active Swift toolchain (Swiftly or Xcode) |

### Flutter (`flutter.zsh`)
| Function | Usage | Description |
|---|---|---|
| `fclean` | `fclean` | `flutter clean` + `flutter pub get` |

### PostgreSQL (`postgres.zsh`)
| Function | Usage | Description |
|---|---|---|
| `pgstart` | `pgstart` | Start Postgres.app |
| `pgstop` | `pgstop` | Stop Postgres.app |

### SSH (`ssh.zsh`)
| Function | Usage | Description |
|---|---|---|
| `sshpubkey` | `sshpubkey` | Copy public key to clipboard |

---

## Active Completions (`completions.zsh`)

| Tool | Description |
|---|---|
| Docker | Subcommands, flags, container and image names |
| cargo | Subcommands, flags, workspace crates, targets (loaded via rustc sysroot fpath) |
| rustup | Toolchains, components, cross-compilation targets |
| kubectl | Resources, namespaces, contexts, flags |
| pnpm | Subcommands, package.json scripts, flags |
| swiftly | Subcommands install, use, list, uninstall, Swift versions |
| npm | Subcommands and scripts (lazy-loaded first time nvm is used) |
| pyenv | Subcommands and Python versions (included in cached init, `tools.zsh`) |
| starship | Starship CLI subcommands |

> Completions for rustup, kubectl, swiftly, pnpm and starship are cached in `~/.cache/` and automatically regenerated when the binary updates. Cargo completions load via `fpath` (no explicit cache, managed by `compinit`). Pyenv completions are included in the cached init script (`pyenv_init.zsh`).

---

## Environment Variables

Variables that influence shell behavior or repo scripts.

### Repo Paths
| Variable | Default | Description |
|---|---|---|
| `DOTFILES` | ~/.dotfiles | Repo root; opt-in override via `DOTFILES=/path zsh -i` |

### Version Managers
| Variable | Default | Description |
|---|---|---|
| `SWIFTLY_HOME` | ~/.swiftly | Swiftly directory; set in `exports.zsh` |
| `NVM_DIR` | ~/.nvm | nvm directory; set in `exports.zsh` |
| `NVM_CURRENT_NODE_VERSION` | (resolved via nvm in tools.zsh) | Default Node version from nvm; its `bin/` is added to PATH on startup |
| `PYENV_ROOT` | ~/.pyenv | pyenv directory; set in `exports.zsh` |

### Cache and XDG Paths
| Variable | Default | Description |
|---|---|---|
| `XDG_CACHE_HOME` | ~/.cache | Cache directory (completions, brew shellenv, starship init, pyenv init, brew prefixes, xcode sdkroot, rustc sysroot) |

### AI / Local Models
| Variable | Default | Description |
|---|---|---|
| `LMSTUDIO_HOME` | ~/.lmstudio | LM Studio directory; `bin/` is added to PATH if it exists |

### Development and CI Flags
| Variable | Default | Description |
|---|---|---|
| `ZPROF` | — | If `=true`, activates startup profiler (`zprof`) on shell startup |
| `SKIP_BREWFILE` | — | If set, skips check 5 in `./test.sh`; reserved for CI, don't use locally |

---

## Declared Dependencies (Brewfile)

All packages are installed with `brew bundle --file=Brewfile`. Idempotent — only installs what's missing.

### Base Shell
| Formula | Purpose |
|---|---|
| `starship` | Prompt; config in `config/starship.toml` |
| `zsh-syntax-highlighting` | Syntax highlighting; loaded at end of `.zshrc` |

### Terminal Utilities
| Formula | Purpose |
|---|---|
| `bat` | File viewer with syntax highlighting and git integration |
| `eza` | Modern directory listing with git status (aliases `ls`/`ll`/`la`) |
| `exiftool` | Read and write EXIF metadata |
| `htop` | Interactive process viewer |
| `jq` | CLI JSON processing (used by `json()`) |
| `ncdu` | Disk usage in NCurses interface |
| `tlrc` | Official tldr client |
| `tree` | Directory tree (used by `tre()`) |
| `wget` | File download |

### Compression
| Formula | Purpose |
|---|---|
| `pigz` | Parallel gzip on multi-core (used by `targz()`) |

### Git
| Formula | Purpose |
|---|---|
| `git-lfs` | Git Large File Storage; configured in `config/gitconfig` |
| `git-town` | High-level Git workflow CLI (sync, ship, hack…) |
| `ejoffe/tap/spr` | Stacked pull requests on GitHub |
| `withgraphite/tap/graphite` | Stacked PRs and code review on GitHub |

### Language Version Managers
| Formula | Purpose |
|---|---|
| `rbenv` | Ruby version manager; lazy-loaded in `tools.zsh` |
| `nvm` | Node version manager; lazy-loaded in `tools.zsh` |
| `pyenv` | Python version manager; init cached in `tools.zsh` |

### JavaScript / Node
| Formula | Purpose |
|---|---|
| `pnpm` | Preferred package manager over npm |
| `yarn` | Alternative package manager |

### Python
| Formula | Purpose |
|---|---|
| `uv` | Ultra-fast Python package installer and resolver |
| `hatch` | Modern, extensible Python project management |

### iOS / macOS — Dependencies and Tooling
| Formula | Purpose |
|---|---|
| `cocoapods` | Cocoa dependency manager |
| `carthage` | Decentralized Cocoa dependency manager |
| `xcode-build-server` | Integrates Xcode with sourcekit-lsp |
| `swift-format` | Official Swift formatter |
| `swiftformat` | Alternative Swift formatter |
| `swiftlint` | Swift style linter |
| `xcbeautify` | Beautifier for `xcodebuild` output |
| `xcodegen` | Generate `.xcodeproj` from spec and folder structure |
| `xcresultparser` | Parse `.xcresult` from builds and tests |
| `getsentry/xcodebuildmcp/xcodebuildmcp` | MCP server for Xcode project workflows (XcodeBuildMCP) |

### Swift Server-Side
| Formula | Purpose |
|---|---|
| `vapor` | Vapor CLI (Swift web framework) |

### Cloud / Remote Dev
| Formula | Purpose |
|---|---|
| `kubectl` | Kubernetes CLI; alias `k=` and cached completions |
| `gh` | GitHub CLI; cached completions |

### Scripting / Lint
| Formula | Purpose |
|---|---|
| `shellcheck` | Static linter for bash/sh scripts |
| `cmake` | Cross-platform build system |
| `cmark` | Markdown implementation (CommonMark) |

### System Libraries
| Formula | Purpose |
|---|---|
| `gdbm` | GNU database manager (rbenv/pyenv dependency) |
| `libffi` | Portable Foreign Function Interface |
| `zlib` | General-purpose lossless compression |

---

## Repo Validation

`./test.sh` is the main entry point to validate the working tree without affecting the active shell. It runs, in order:

1. Bash syntax of `install.sh`.
2. Zsh syntax of `.zshenv`, `.zshrc`, modules and functions.
3. Chained loading of modules in the order `.zshrc` uses them.
4. Loading with `zprof` active — catches errors that only appear under the profiler.
5. Non-destructive Brewfile validation, delegated to `scripts/check-brewfile.sh`.
6. Anti-drift check of this same reference, delegated to `scripts/check-docs-drift.sh`.
7. Behavioral validation of `install.sh` in a `$HOME` sandbox, delegated to `scripts/check-install.sh` — verifies symlink creation, backup of existing files and idempotence.
8. Runtime validation of documented symbols, delegated to `scripts/check-runtime-symbols.sh` — after sourcing modules in `.zshrc` order, each alias/function listed in this reference must respond to `type`.

Checks 3 and 4 run with `XDG_CACHE_HOME` and `TMPDIR` redirected to an ephemeral temporary directory, so they don't leave caches or loose files on the host. `HOME` and `ZDOTDIR` (zsh's env var for overriding where it looks for dot files) are deliberately preserved to keep the test close to real shell startup behavior.

Check 6 compares aliases from `zsh/aliases.zsh` and functions from `zsh/functions/*.zsh` against rows on this page. If it fails, the message shows which symbols are only in implementation or only in docs. To resolve:

- If the symbol is new and relevant, add its row in the corresponding section on this page.
- If the symbol is obsolete in docs, delete its row.
- If it's an internal helper with no public value, add it to `EXCLUDED_ALIASES` or `EXCLUDED_FUNCTIONS` in `scripts/check-docs-drift.sh` with a brief comment.

Known limits:

- Doesn't run `zsh -i -c exit`. That command would load the installed `~/.zshrc` (potentially a symlink to another clone), not this working tree. So `./test.sh` sources modules directly instead.
- Doesn't install dependencies or modify the host. Brewfile validation only checks parsing, not installed state.
- Brewfile validation passes only with exit `0` from the helper. Any non-zero exit code from the helper is treated as a failure; the helper output explains whether the problem is host-level (`brew` missing, permissions, etc.) or repo-level (invalid content).
- Anti-drift only covers aliases from `zsh/aliases.zsh` and functions from `zsh/functions/*.zsh` against `docs/reference.md`. Doesn't validate `README.md`, `docs/setup.md`, warning messages or internal textual contracts.

Exit: `0` if all passes, `1` if anything fails.

### `SKIP_BREWFILE` Opt-Out

`SKIP_BREWFILE=1 ./test.sh` skips check 5 and marks that entry as `[SKIP]` in the output. Intended for environments where Homebrew state doesn't represent the user's (typically clean CI runners). CI runners start clean without your locally-installed packages, so Homebrew state isn't meaningful there. In local development it should be left undefined so the smoke test keeps covering Brewfile validation. It's not a new mode of the script: doesn't change check order or activate different logic, just skips that one check.

### CI

`.github/workflows/ci.yml` runs `./test.sh` with `SKIP_BREWFILE=1` on a `macos-latest` runner on every push to `main` and on every pull request. Minimal CI covers syntax, chained loading, `zprof` and anti-drift; Homebrew is deliberately outside the critical path. If Brewfile coverage becomes needed in CI, it will be in a separate, non-blocking job, not adding mutable state to the main job.

### `DOTFILES` Override for Interactive Testing

`.zshrc` resolves the repo root from the `DOTFILES` variable. By default it points to `~/.dotfiles`. Exporting `DOTFILES` before starting the shell can point to an alternate clone to validate changes interactively without moving symlinks:

```zsh
DOTFILES=~/work/dotfiles-fork zsh -i
```

Minimal validation of the override: directory exists + `.zshrc` readable + `.zshenv` readable. If it fails, `.zshrc` prints a warning to stderr and falls back to `~/.dotfiles`; no auto-detection or automatic clone search, the choice is always explicit.

**Caveats:**
- This is a convenience shortcut, not a substitute for `./test.sh`. The smoke test remains the main validation point for the working tree.
- Changes to `.zshenv` in your alternate clone won't be picked up — `.zshenv` still loads from `~/.zshenv` (typically symlinked to `~/.dotfiles/.zshenv`).

---

## Startup Profiling

To measure how long each function takes during shell startup:

```zsh
# Quick report (print and exit):
ZPROF=true zsh -i -c exit

# Interactive session with report on exit:
ZPROF=true zsh -i
```

The `time` column shows total accumulated time; `self` is own time without counting calls to other functions. Rows are ordered by cost from highest to lowest — the top ones are candidates for optimization.

### Manual Cache Invalidation

Most caches are automatically invalidated when the binary is newer than the file. Exception:

- **`~/.cache/xcode_sdkroot`**: if you change the active Xcode with `xcode-select -s`, delete it manually to force `xcrun --show-sdk-path` to re-run on the next shell startup.
