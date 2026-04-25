# Cleans the Flutter project and reinstalls all dependencies from scratch.
# Useful when there are cache issues or pubspec.yaml changes that are not reflected.
# Usage: fclean
function fclean() {
    flutter clean && flutter pub get;
}
