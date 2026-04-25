# Disables Terminal.app automatic session restore.
# IMPORTANT: must be in .zshenv (not .zshrc). The system helper
# /etc/zshrc_Apple_Terminal runs between .zshenv and .zshrc, so by the time
# .zshrc is reached it is too late to inhibit session saving/restoring.
SHELL_SESSIONS_DISABLE=1

# Load Cargo (Rust) environment only if installed.
# .zshenv runs in all shell contexts (interactive, non-interactive, scripts),
# so the check matters: avoids errors if Rust is not present on this machine.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
