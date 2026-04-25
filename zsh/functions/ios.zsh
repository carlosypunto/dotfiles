# Removes the Xcode DerivedData folder entirely.
# Fixes most bizarre build issues without touching the project.
# Usage: xcclean
function xcclean() {
    local derived_data=~/Library/Developer/Xcode/DerivedData
    if [[ ! -d "$derived_data" ]]; then
        echo "DerivedData does not exist, nothing to delete."
        return 0
    fi
    local size=$(du -sh "$derived_data" 2>/dev/null | cut -f1)
    echo "Removing DerivedData… ($size)"
    rm -rf "$derived_data"
    echo "Done."
}

# Opens the Xcode project in the current directory: looks for a .xcworkspace
# (which includes CocoaPods/SPM dependencies) first; falls back to .xcodeproj.
# Usage: xcopen
function xcopen() {
    local workspace=$(find . -maxdepth 2 -name "*.xcworkspace" ! -path "*/xcshareddata/*" ! -path "*/.swiftpm/*" | head -1);
    local project=$(find . -maxdepth 2 -name "*.xcodeproj" | head -1);

    if [[ -n "$workspace" ]]; then
        open "$workspace";
    elif [[ -n "$project" ]]; then
        open "$project";
    else
        echo "No .xcworkspace or .xcodeproj found in the current directory.";
    fi;
}

# Lists available and ready-to-use iOS/macOS simulators.
# Filters out unavailable ones to show only those that can be booted.
# Usage: simlist
function simlist() {
    xcrun simctl list devices available;
}

# Shows the active Swift toolchain and its version.
# If Swiftly is managing the toolchain, indicates which one is selected.
# Otherwise shows the Xcode bundled toolchain.
# Usage: swift-version
function swift-version() {
    swift --version 2>/dev/null || echo "Swift not found in PATH.";
    echo "";
    if command -v swiftly &>/dev/null; then
        echo "Toolchain managed by Swiftly:";
        swiftly list | grep '\*' || echo "  (none active — using Xcode toolchain)";
    else
        echo "Swiftly not installed — using Xcode bundled toolchain.";
    fi;
}

# Boots an iOS/macOS simulator by searching for it by name (partial, case-insensitive).
# Usage: simboot "iPhone 15 Pro"
function simboot() {
    local name="${1:?Usage: simboot <simulator-name>}"
    local udid
    udid=$(xcrun simctl list devices available | grep -i "$name" | grep -oE '[A-F0-9-]{36}' | head -1)
    if [[ -z "$udid" ]]; then
        echo "simboot: no simulator found matching '$name'" >&2
        return 1
    fi
    xcrun simctl boot "$udid"
}
