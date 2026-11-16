#!/usr/bin/env bash
# SDK-based build without requiring Theos staging tools (rsync/fakeroot).
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
: "${THEOS:?Set THEOS to your Theos checkout}"
sdk_path="${SDK_PATH:-$THEOS/sdks/iPhoneOS15.6.sdk}"
toolchain_bin="${IOS_TOOLCHAIN_BIN:-$THEOS/toolchain/linux/iphone/bin}"
export PATH="$toolchain_bin:$PATH"
test -d "$sdk_path" || { echo 'iPhoneOS15.6 SDK not found' >&2; exit 1; }
for command_name in clang ldid dpkg-deb python3; do
    command -v "$command_name" >/dev/null || { echo "Missing: $command_name" >&2; exit 1; }
done
build_dir="$project_dir/build"
stage_dir="$build_dir/stage"
# Only delete the fixed staging directory inside this project.
rm -rf "$stage_dir"
mkdir -p "$stage_dir/DEBIAN" "$build_dir" "$project_dir/packages"
inject_dir="$stage_dir/var/jb/Library/MobileSubstrate/DynamicLibraries"
prefs_dir="$stage_dir/var/jb/Library/PreferenceBundles/SenSwipePrefs.bundle"
mkdir -p "$inject_dir" "$prefs_dir"

compile_flags=(-target arm64-apple-ios15.0 -isysroot "$sdk_path" -fobjc-arc
    -O2 -Wall -Wextra -Werror -fvisibility=hidden
    -I "$THEOS/vendor/include" -F "$THEOS/vendor/lib/iphone/rootless"
    -F "$sdk_path/System/Library/PrivateFrameworks")
rootless_link_flags=(-Wl,-rpath,/var/jb/Library/Frameworks
    -Wl,-rpath,@loader_path/.jbroot/Library/Frameworks)

clang "${compile_flags[@]}" -dynamiclib "$project_dir/Sources/Tweak.m" \
    -framework Foundation -lobjc -L "$THEOS/vendor/lib/iphone/rootless" -lsubstrate \
    "${rootless_link_flags[@]}" -Wl,-install_name,@rpath/SenSwipe.dylib \
    -o "$inject_dir/SenSwipe.dylib"
ldid -S -Cadhoc "$inject_dir/SenSwipe.dylib"
cp "$project_dir/SenSwipe.plist" "$inject_dir/"

clang "${compile_flags[@]}" -bundle "$project_dir/Preferences/SENSRootListController.m" \
    -framework Foundation -framework UIKit -framework Preferences -lobjc \
    -o "$prefs_dir/SenSwipePrefs"
ldid -S -Cadhoc "$prefs_dir/SenSwipePrefs"
cp "$project_dir/Preferences/Resources/Info.plist" "$prefs_dir/Info.plist"
cp "$project_dir/Preferences/Resources/Root.plist" "$prefs_dir/Root.plist"
cp -R "$project_dir/layout/Library/PreferenceLoader" "$stage_dir/var/jb/Library/"
cp "$project_dir/control" "$stage_dir/DEBIAN/control"
docs_dir="$stage_dir/var/jb/usr/share/doc/vn.sentechtips.senswipe"
mkdir -p "$docs_dir"
cp "$project_dir/LICENSE" "$docs_dir/copyright"
find "$stage_dir" -type d -exec chmod 755 {} +
find "$stage_dir" -type f -exec chmod 644 {} +
chmod 755 "$inject_dir/SenSwipe.dylib" "$prefs_dir/SenSwipePrefs"
package_path="$project_dir/packages/SenSwipe-0.1.0-beta1-iphoneos-arm64.deb"
dpkg-deb --root-owner-group -Zxz -z9 --build "$stage_dir" "$package_path"
python3 "$project_dir/scripts/verify_package.py" "$package_path"
