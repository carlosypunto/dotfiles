# Environment Setup from Scratch

Guide to setting up the complete environment on a new machine. By the end, you'll have a fully working shell with all tools active and ready to use. For a machine already configured with Homebrew, the quick installation section in [README](../README.md) is sufficient.

---

## Phase A — Base Tools (not installable via Homebrew)

### 1. Xcode and Command Line Tools

```zsh
# From the App Store: install full Xcode (required for iOS/macOS development)
sudo xcodebuild -license accept
xcode-select --install
```

### 2. Homebrew

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Swiftly — Swift toolchain manager

Complements Xcode for server-side Swift and SPM. Allows you to install and switch Swift versions independently of Xcode's bundled toolchain. See [docs/swift.md](swift.md) for more details.

```zsh
curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
swiftly install latest
```

### 4. Rust — via rustup

```zsh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

---

## Phase B — Dotfiles and Dependencies

### 5. Clone the repo and create symlinks

```zsh
git clone <url> ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` creates symlinks for:
- `~/.zshrc`
- `~/.zshenv`
- `~/.config/starship.toml`
- `~/.editorconfig`
- `~/.gitconfig`

It also generates an empty stub of `~/.gitconfig.local` if it doesn't exist.

#### Git Configuration

Git is configured to keep private identity data (name, email, signing key) out of version control.

`~/.gitconfig` points to `config/gitconfig` from this repo (versioned, no private data). At the end of the file there's an `[include]` that automatically loads `~/.gitconfig.local`:

```
# ~/.gitconfig  (versioned, managed by this repo)
[user]
    # no name or email here — they go in .gitconfig.local
[core]
    editor = zed --wait
[diff]
    tool = Kaleidoscope
# ... rest of public config ...
[include]
    path = ~/.gitconfig.local   ← always loaded at the end
```

```
# ~/.gitconfig.local  (NOT versioned, machine-specific)
[user]
    name  = Your Name
    email = your@email.com
    signingkey = ~/.ssh/id_ed25519.pub
[commit]
    gpgsign = true
```

`install.sh` creates `~/.gitconfig.local` with a commented template the first time. Edit it with your machine's data before making the first commit.

#### Protection of Existing Files

`install.sh` never silently overwrites. For each destination (`~/.zshrc`, `~/.zshenv`, `~/.config/starship.toml`, `~/.editorconfig`, `~/.gitconfig`):

- If it's already a symlink pointing to the correct file from the repo → no changes (`[ok]`).
- If it exists as a real file or different symlink → it backs it up with timestamp before creating the new symlink (`[backup]` + `[linked]`): `<destination>.bak.YYYYMMDDHHMMSS`.

The script doesn't delete old backups. At the end of each run it warns about the cumulative count:

```zsh
# Inspect existing backups:
find "$HOME" "$HOME/.config" -maxdepth 1 -name '*.bak.*'

# Delete after review:
find "$HOME" "$HOME/.config" -maxdepth 1 -name '*.bak.*' -delete
```

`~/.gitconfig.local` is respected if it already exists — never backed up or overwritten, because it contains local configuration (identity, commit signing) that shouldn't be lost.

This behavior is covered by check 7 of `./test.sh` (`scripts/check-install.sh`), which runs `install.sh` in a sealed temporary `$HOME` and validates symlinks, backups and idempotence without touching the real environment.

### 6. Install dependencies via Brewfile

```zsh
brew bundle --file=Brewfile
```

This installs tools, package managers, language runtimes, and several GUI apps. See [docs/reference.md](reference.md#declared-dependencies-brewfile) for the full list with purposes for each package.

It's idempotent — can be run multiple times with no side effects.

> Some casks (Docker, Postgres.app, Kaleidoscope) are commented in the `Brewfile` due to volatile names. Review them and uncomment as needed.

**Starship (prompt):** installed as part of the Brewfile. Its configuration (`~/.config/starship.toml`) was already created by `install.sh` in the previous step as a symlink to `config/starship.toml` from the repo. Works with defaults without needing to edit the file.

---

## Phase C — Configure Language Versions

Once the tools are installed, you need to select the active versions.

### 7. Ruby — via rbenv

```zsh
source ~/.zshrc          # activates rbenv lazy-load
rbenv install 3.4.3      # or the most recent stable version
rbenv global 3.4.3
```

### 8. Node — via nvm

```zsh
source ~/.zshrc          # activates nvm lazy-load
nvm install --lts
nvm alias default node
```

> **nvm and Homebrew**: `brew bundle` installs nvm via Homebrew (`/opt/homebrew/opt/nvm/nvm.sh`). The lazy-loader in `tools.zsh` automatically detects both this path and the curl installer path (`~/.nvm/nvm.sh`), so both installations work without configuration changes.

### 9. Python — via pyenv

```zsh
source ~/.zshrc          # activates pyenv (init cached in tools.zsh)
pyenv install 3.13.3     # or the most recent stable version
pyenv global 3.13.3
```

> Unlike rbenv/nvm, pyenv doesn't use lazy-load (initialized on first use, not at shell startup): its `init` is cached in `~/.cache/pyenv_init.zsh` and sourced directly in `tools.zsh`. The cache is automatically regenerated when the pyenv binary updates.

---

## Phase D — Activate and Verify

```zsh
source ~/.zshrc
./test.sh
```

`test.sh` validates your setup by running eight checks. If everything passes with exit 0, the environment is ready. See [docs/reference.md — Repo Validation](reference.md#repo-validation) for details on what each check does and its limits.

---

## Expected Environment

### Node.js
- **nvm** as version manager — only Node installed, no versions via Homebrew directly
- **pnpm** as main package manager; **npm** is still available via nvm but pnpm is preferred
- **yarn** is not used — `.yarn/`, `.yarnrc` and `~/node_modules` globals can be removed if they exist

### Ruby
- **rbenv** as version manager — no system Ruby or via Homebrew directly

### Python
- **pyenv** as version manager — no system Python or via Homebrew directly

### Rust
- **rustup** as toolchain manager

### Swift
- **Swiftly** for additional toolchains — Xcode is still required for iOS/macOS development

### Prompt
- **Starship** — installed via Brewfile; configuration in `~/.config/starship.toml`
- Don't use Powerlevel10k or Oh My Zsh
