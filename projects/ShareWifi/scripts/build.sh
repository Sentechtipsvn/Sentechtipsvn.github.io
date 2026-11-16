#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
: "${THEOS:?Set THEOS}"
: "${SDK_PATH:?Set SDK_PATH to iPhoneOS15.6.sdk}"
: "${IOS_TOOLCHAIN_BIN:?Set IOS_TOOLCHAIN_BIN to the iOS cross-toolchain bin directory}"
export PATH="$IOS_TOOLCHAIN_BIN:$PATH"
stage="$project_dir/build/stage"
rm -rf "$stage"
app="$stage/var/jb/Applications/ShareWifi.app"
inject="$stage/var/jb/Library/MobileSubstrate/DynamicLibraries"
module="$stage/var/jb/Library/ControlCenter/Bundles/ShareWifiModule.bundle"
mkdir -p "$module" "$app" "$inject" "$stage/DEBIAN" "$project_dir/packages"
common=(-target arm64-apple-ios15.0 -isysroot "$SDK_PATH" -fobjc-arc -O2
    -Wall -Wextra -Werror -fvisibility=hidden -I "$project_dir/Sources")
clang "${common[@]}" -dynamiclib "$project_dir/Sources/Controller.m" "$project_dir/Sources/SWHapticMenu.m" \
    "$project_dir/Sources/SWClients.m" "$project_dir/Sources/SWArp.c" \
    -framework UIKit -framework Foundation -lobjc \
    -L "$THEOS/vendor/lib/iphone/rootless" -lsubstrate \
    -Wl,-rpath,/var/jb/Library/Frameworks -Wl,-rpath,@loader_path/.jbroot/Library/Frameworks \
    -Wl,-install_name,@rpath/ShareWifi.dylib -o "$inject/ShareWifi.dylib"
ldid -S -Cadhoc "$inject/ShareWifi.dylib"
clang "${common[@]}" "$project_dir/App/main.m" "$project_dir/App/SWSettings.m" -framework UIKit -framework Foundation -lobjc -o "$app/ShareWifi"
ldid -S"$project_dir/Resources/App.entitlements" -Cadhoc "$app/ShareWifi"
clang "${common[@]}" -bundle "$project_dir/ControlCenter/ShareWifiModule.m" \
    -I "$THEOS/vendor/include" -F "$SDK_PATH/System/Library/PrivateFrameworks" \
    -framework ControlCenterUIKit -framework UIKit -framework Foundation -lobjc -o "$module/ShareWifiModule"
ldid -S -Cadhoc "$module/ShareWifiModule"
cp "$project_dir/ControlCenter/Info.plist" "$module/Info.plist"
cp "$project_dir/ControlCenter/"*.png "$module/"
cp "$project_dir/Resources/Info.plist" "$app/Info.plist"
cp "$project_dir/Resources/"*.png "$app/"
cp "$project_dir/ShareWifi.plist" "$inject/ShareWifi.plist"
cp "$project_dir/control" "$stage/DEBIAN/control"
cp "$project_dir/layout/DEBIAN/"* "$stage/DEBIAN/"
doc="$stage/var/jb/usr/share/doc/vn.sentechtips.sharewifi"
mkdir -p "$doc"
cp "$project_dir/LICENSE" "$doc/copyright"
find "$stage" -type d -exec chmod 755 {} +
find "$stage" -type f -exec chmod 644 {} +
chmod 755 "$module/ShareWifiModule" "$app/ShareWifi" "$inject/ShareWifi.dylib" "$stage/DEBIAN/postinst" "$stage/DEBIAN/prerm"
dpkg-deb --root-owner-group -Zxz -z9 --build "$stage" "$project_dir/packages/ShareWifi-0.2.1-beta1-iphoneos-arm64.deb"
