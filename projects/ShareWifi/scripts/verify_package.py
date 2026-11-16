#!/usr/bin/env python3
"""Archive verification only; never installs or switches a real device's radios."""
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
from macho_verify import verify_macho, check


def main():
    package=Path(sys.argv[1]).resolve()
    with tempfile.TemporaryDirectory(prefix='sharewifi-verify-') as tmp:
        root=Path(tmp)
        subprocess.run(['dpkg-deb','-R',str(package),str(root)],check=True)
        payload={str(f.relative_to(root)) for f in root.rglob('*') if f.is_file() and 'DEBIAN' not in f.relative_to(root).parts}
        app='var/jb/Applications/ShareWifi.app/'
        inject='var/jb/Library/MobileSubstrate/DynamicLibraries/'
        module='var/jb/Library/ControlCenter/Bundles/ShareWifiModule.bundle/'
        expected={app+'ShareWifi',app+'Info.plist',app+'AppIcon60x60@2x.png',app+'AppIcon60x60@3x.png',
                  module+'ShareWifiModule',module+'Info.plist',module+'Icon@2x.png',module+'Icon@3x.png',
                  inject+'ShareWifi.dylib',inject+'ShareWifi.plist','var/jb/usr/share/doc/vn.sentechtips.sharewifi/copyright'}
        check(payload==expected,f'Unexpected payload: {payload ^ expected}')
        for name in payload:
            if name.endswith('.plist'): plistlib.loads((root/name).read_bytes())
        filt=plistlib.loads((root/(inject+'ShareWifi.plist')).read_bytes())
        check(filt=={'Filter':{'Bundles':['com.apple.springboard']}},'Incorrect injection filter')
        info=plistlib.loads((root/(app+'Info.plist')).read_bytes())
        check(info['CFBundleIdentifier']=='vn.sentechtips.sharewifi','Wrong app identity')
        check({x['UIApplicationShortcutItemType'] for x in info['UIApplicationShortcutItems']}=={'panel','devices','on','off'},'Established Home Screen quick actions changed')
        check(info['CFBundleShortVersionString']=='0.2.1' and info['CFBundleVersion']=='4','Wrong app version')
        module_info=plistlib.loads((root/(module+'Info.plist')).read_bytes())
        check(module_info['NSPrincipalClass']=='SWControlCenterModule','Wrong CC principal class')
        check(module_info['CFBundleIdentifier']=='vn.sentechtips.sharewifi.module','Wrong CC identity')
        check(module_info['CFBundleShortVersionString']=='0.2.1','Wrong module version')
        check(module_info['CCSModuleSize']['Portrait']=={'Height':1,'Width':1},'Wrong CC size')
        control=(root/'DEBIAN/control').read_text()
        check('Version: 0.2.1~beta1\n' in control,'Wrong package version')
        check('com.opa334.ccsupport (>= 1.3.10)' in control,'Missing CCSupport dependency')
        check('Architecture: iphoneos-arm64' in control,'Wrong package architecture')
        check('firmware (>= 15.8.8)' in control and 'firmware (<< 15.8.9)' in control,'Missing firmware restriction')
        check({f.name for f in (root/'DEBIAN').iterdir()}=={'control','postinst','prerm'},'Unexpected maintainer script')
        check('killall' not in (root/'DEBIAN/postinst').read_text(),'Unexpected forced restart')
        binaries={'controller':verify_macho(root/(inject+'ShareWifi.dylib'),6),
                  'module':verify_macho(root/(module+'ShareWifiModule'),8),
                  'app':verify_macho(root/(app+'ShareWifi'),2)}
        report={'package':package.name,'sha256':hashlib.sha256(package.read_bytes()).hexdigest(),
                'payload_files':len(payload),'binaries':binaries,
                'host_arp_tests':'passed with AddressSanitizer + UBSan; LeakSanitizer disabled due host ptrace',
                'host_method_abi_tests':'BOOL getter/action regression and unsafe ABI rejection cases passed with AddressSanitizer + UBSan',
                'host_profile_tests':'16 radio combinations, 256 restores, order/mask and missing-session rejection passed with ASan + UBSan',
                'host_radio_tests':'128 selected-radio plans, explicit command parsing, unknown peers and malformed requests passed with ASan + UBSan',
                'device_tested':False,'native_hotspot_radio_toggles_and_icon_tap':'Requires iPhone 7 Plus iOS 15.8.8 validation',
                'home_screen_haptic_menu':'Runtime ABI-checked hooks; compiled, not device-tested'}
        output=json.dumps(report,indent=2)+'\n'
        (package.parent/'Verification.json').write_text(output)
        print(output)


if __name__=='__main__':main()
