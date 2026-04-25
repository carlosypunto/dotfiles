# Swift Toolchain Management

Swiftly and Xcode manage toolchains independently. Without understanding this, you might install a new Swift version via Swiftly and find your Xcode build still uses the old bundled version. Here's how to keep them straight.

## Swiftly Toolchains (terminal / server-side / SPM)

```zsh
swiftly install latest      # installs the latest stable Swift
swiftly install 6.0         # installs a specific version
swiftly use latest          # activates a toolchain in the shell
swiftly use system          # reverts to Xcode's bundled toolchain in the shell
swiftly list                # lists installed toolchains
swiftly uninstall 5.10      # removes a toolchain
swift-version               # shows the active toolchain (function from these dotfiles)
```

## Xcode Toolchain (iOS / macOS)

Xcode includes its own bundled Swift and manages it independently from **Settings → Components → Toolchains**. You can also install additional toolchains from swift.org and they will appear in that menu. This is useful if you need a specific Swift release not yet available in Swiftly.

## Coexistence between both

| Context | Toolchain used |
|---|---|
| Terminal (`swift`, `swiftc`) | The one active in Swiftly (`swiftly use`) |
| Xcode (app compilation) | The one selected in Xcode Settings |
| `xcodebuild` with Swiftly | Export `TOOLCHAINS=swift` to force Swiftly's toolchain. `TOOLCHAINS=swift` is an Xcode env var that forces the active Swiftly toolchain as the Swift compiler. |
| Without Swiftly active | Xcode bundled (via `xcrun`) |
