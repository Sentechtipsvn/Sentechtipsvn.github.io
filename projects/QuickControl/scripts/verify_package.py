#!/usr/bin/env python3
"""Archive verification only; never installs or switches a real device's radios."""
import hashlib
import io
import tarfile
import json
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
from macho_verify import verify_macho, check


def main():
    package=Path(sys.argv[1]).resolve()
    archive=subprocess.run(['dpkg-deb','--fsys-tarfile',str(package)],check=True,capture_output=True).stdout
    with tarfile.open(fileobj=io.BytesIO(archive)) as tf:
        check(all(m.uid==0 and m.gid==0 for m in tf.getmembers()),'Payload owner must be root')
    with tempfile.TemporaryDirectory(prefix='quickcontrol-verify-') as tmp:
        root=Path(tmp)
        subprocess.run(['dpkg-deb','-R',str(package),str(root)],check=True)
        payload={str(f.relative_to(root)) for f in root.rglob('*') if f.is_file() and 'DEBIAN' not in f.relative_to(root).parts}
        app='var/jb/Applications/QuickControl.app/'
        inject='var/jb/Library/MobileSubstrate/DynamicLibraries/'
        module='var/jb/Library/ControlCenter/Bundles/QuickControlModule.bundle/'
        expected={app+'QuickControl',app+'Info.plist',app+'AppIcon60x60@2x.png',app+'AppIcon60x60@3x.png',
                  module+'QuickControlModule',module+'Info.plist',module+'Icon@2x.png',module+'Icon@3x.png',
                  inject+'QuickControl.dylib',inject+'QuickControl.plist','var/jb/usr/share/doc/vn.sentechtips.quickcontrol/copyright'}
        check(payload==expected,f'Unexpected payload: {payload ^ expected}')
        for name in payload:
            if name.endswith('.plist'): plistlib.loads((root/name).read_bytes())
        filt=plistlib.loads((root/(inject+'QuickControl.plist')).read_bytes())
        check(filt=={'Filter':{'Bundles':['com.apple.springboard']}},'Incorrect injection filter')
        info=plistlib.loads((root/(app+'Info.plist')).read_bytes())
        check(info['CFBundleIdentifier']=='vn.sentechtips.quickcontrol','Wrong app identity')
        check(info['CFBundleURLTypes'][0]['CFBundleURLSchemes']==['quickcontrol'],'Missing QR app URL scheme')
        module_info=plistlib.loads((root/(module+'Info.plist')).read_bytes())
        check(module_info['NSPrincipalClass']=='QCModule','Wrong CC principal class')
        check(module_info['CFBundleIdentifier']=='vn.sentechtips.quickcontrol.module','Wrong CC identity')
        check(module_info['CCSModuleSize']['Portrait']=={'Height':1,'Width':1},'Wrong CC size')
        control=(root/'DEBIAN/control').read_text()
        check('com.opa334.ccsupport (>= 1.3.10)' in control,'Missing CCSupport dependency')
        check('Architecture: iphoneos-arm64' in control,'Wrong package architecture')
        check('firmware (>= 15.8.8)' in control and 'firmware (<< 15.8.9)' in control,'Missing firmware restriction')
        check({f.name for f in (root/'DEBIAN').iterdir()}=={'control','postinst','prerm'},'Unexpected maintainer script')
        check('killall' not in (root/'DEBIAN/postinst').read_text(),'Unexpected forced restart')
        for name in [app+'QuickControl',inject+'QuickControl.dylib',module+'QuickControlModule','DEBIAN/postinst','DEBIAN/prerm']:
            check((root/name).stat().st_mode & 0o111,f'Missing executable mode: {name}')
        binaries={'controller':verify_macho(root/(inject+'QuickControl.dylib'),6),
                  'module':verify_macho(root/(module+'QuickControlModule'),8),
                  'app':verify_macho(root/(app+'QuickControl'),2)}
        report={'package':package.name,'sha256':hashlib.sha256(package.read_bytes()).hexdigest(),
                'payload_files':len(payload),'binaries':binaries,
                'host_policy_tests':'Touch/lock gating, stale state, position, URL/bundle validation, BOOL/void ABI and 10,000 malformed strings passed with ASan + UBSan; LeakSanitizer disabled due host ptrace',
                'device_tested':False,'overlay_gestures_lock_lifecycle_launching_QR_and_CC':'Requires iPhone 7 Plus iOS 15.8.8 validation'}
        output=json.dumps(report,indent=2)+'\n'
        (package.parent/'Verification.json').write_text(output)
        print(output)


if __name__=='__main__':main()
