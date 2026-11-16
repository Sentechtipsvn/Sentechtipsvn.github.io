#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
: "${SDK_PATH:?Set SDK_PATH}"
: "${IOS_TOOLCHAIN_BIN:?Set IOS_TOOLCHAIN_BIN}"
: "${THEOS_HEADERS:?Set THEOS_HEADERS to the Theos headers checkout}"
export PATH="$IOS_TOOLCHAIN_BIN:$PATH"
stage="$project_dir/build/stage"
rm -rf "$stage"
app="$stage/var/jb/Applications/QuickControl.app"
inject="$stage/var/jb/Library/MobileSubstrate/DynamicLibraries"
module="$stage/var/jb/Library/ControlCenter/Bundles/QuickControlModule.bundle"
mkdir -p "$app" "$inject" "$module" "$stage/DEBIAN" "$project_dir/packages"
flags=(-target arm64-apple-ios15.0 -isysroot "$SDK_PATH" -fobjc-arc -O2 -Wall -Wextra -Werror
    -fvisibility=hidden -I "$project_dir/Sources")
clang "${flags[@]}" -dynamiclib "$project_dir/Sources/Overlay.m" -framework UIKit -framework CoreGraphics -framework Foundation -framework QuartzCore -lobjc \
    -Wl,-install_name,@rpath/QuickControl.dylib -o "$inject/QuickControl.dylib"
ldid -S -Cadhoc "$inject/QuickControl.dylib"
clang "${flags[@]}" "$project_dir/App/main.m" -framework UIKit -framework CoreGraphics -framework Foundation -framework CoreImage -lobjc -o "$app/QuickControl"
ldid -S"$project_dir/Resources/App.entitlements" -Cadhoc "$app/QuickControl"
clang "${flags[@]}" -bundle "$project_dir/ControlCenter/Module.m" -I "$THEOS_HEADERS" \
    -F "$SDK_PATH/System/Library/PrivateFrameworks" -framework ControlCenterUIKit -framework UIKit -framework CoreGraphics -framework Foundation -lobjc -o "$module/QuickControlModule"
ldid -S -Cadhoc "$module/QuickControlModule"
cp "$project_dir/Resources/Info.plist" "$app/Info.plist"
cp "$project_dir/Resources/"*.png "$app/"
cp "$project_dir/ControlCenter/Info.plist" "$module/Info.plist"
cp "$project_dir/ControlCenter/"*.png "$module/"
cp "$project_dir/QuickControl.plist" "$inject/QuickControl.plist"
cp "$project_dir/control" "$stage/DEBIAN/control"
cp "$project_dir/layout/DEBIAN/"* "$stage/DEBIAN/"
doc="$stage/var/jb/usr/share/doc/vn.sentechtips.quickcontrol"
mkdir -p "$doc"
cp "$project_dir/LICENSE" "$doc/copyright"
find "$stage" -type d -exec chmod 755 {} +
find "$stage" -type f -exec chmod 644 {} +
chmod 755 "$app/QuickControl" "$inject/QuickControl.dylib" "$module/QuickControlModule" "$stage/DEBIAN/postinst" "$stage/DEBIAN/prerm"
dpkg-deb --root-owner-group -Zxz -z9 --build "$stage" "$project_dir/packages/QuickControl-0.1.0-beta1-iphoneos-arm64.deb"
