# ShareWifi 0.2.1 beta 1 — Build verification

## Result

Compiled the app, SpringBoard controller and Control Center module for arm64 with iPhoneOS15.6 SDK, Clang 11.1.0, `-Wall -Wextra -Werror`, Theos rootless stubs and ldid. Package verification passed for 11 rootless payload files and all three Mach-O code signatures/code pages. SHA-256 is recorded in `packages/Verification.json`.

This environment has no physical iPhone or SpringBoard simulator. The new UISwitch controls and Home Screen menu have not been exercised on-device. Existing user feedback covers the 0.1.1 sharing functions and the presence of the 0.2.0 Control Center module.

## Changes checked

- Four native UISwitch accessories in the app; controls stay tied to controller readback and are unavailable while busy, pending, stale or unknown.
- Individual requests contain an explicit radio and target state. The plan contains exactly one radio; all other states are preserved as targets and their setters are never scheduled for this request. iOS may independently change dependent radios/hotspot.
- Hotspot-on preflight requires data and Wi-Fi to be on; the full-on action retains its original dependency order.
- Runtime-checked SBIconView shortcut-item getter and shortcut activation class hooks, scoped to ShareWifi. Optional provider hook is guarded separately. Only object/void signatures with the expected argument counts/types are accepted; exceptions fall back to the original menu.
- New menu entries use live power reads and explicit target states. Unknown values offer refresh only. The original four static shortcuts remain in Info.plist and are retained in the augmented list. Editing/removal actions are not intercepted.
- Settings include Haptic Touch enable/disable and four menu-visibility choices, all enabled by default. The old settings keys and aliases are preserved on writes.
- Individual operations preserve the current session; a valid initial hotspot-on can capture a session. Undo uses a full, valid pre-operation snapshot and the corresponding prior session. No-op individual requests do not replace Undo.
- Version remains in 0.2.x so QuickControl 0.1.0's existing version check continues to accept ShareWifi. Request/status paths and the Control Center Darwin notification remain unchanged.

## Host tests

All four suites passed with GCC AddressSanitizer and UndefinedBehaviorSanitizer; LeakSanitizer is disabled because the build host uses ptrace.

| Suite | Coverage |
| --- | --- |
| ARP | Stream framing, interface padding, batches, truncation, invalid MAC/sockaddr and unknown ABI |
| Method ABI | BOOL getter/action, void action and unsafe signature rejection |
| Profiles | 16 power combinations, 256 restores, order/mask, missing state/session and session capture |
| Individual radio | 128 explicit-target plans, exactly one scheduled radio, unknown peers and malformed commands |

## Package checks

- Package/app/module IDs, version 0.2.1/build 4, architecture and exact iOS 15.8.8 dependency bounds.
- Four original static Home Screen shortcut types: panel, devices, on and off.
- CCSupport dependency, module principal class/size, SpringBoard-only injection filter.
- Maintainer script inventory, permissions, root archive ownership and no forced restart from postinst.
- arm64 Mach-O types, deployment target, dependencies/rpaths and ad-hoc code-page integrity for app/controller/module.

## Device checks still needed

- Right-side switch layout in portrait/landscape and large text; readback and errors for each radio.
- Home Screen getter/activation paths on iOS 15.8.8, menu capacity/order, labels and settings visibility. ABI validation does not prove the live menu uses the intercepted path.
- Actual radio privileges and timing, including switching Wi-Fi/data off during hotspot sharing and hotspot activation with Bluetooth off.
- Undo and restore after a sequence of individual operations, all three stop modes, Control Center and QuickControl integration.
- Concurrent changes from Settings, stale menus, rapid taps, missing signal/SIM, Airplane Mode and respring.
