#!/usr/bin/env python3
"""Run Sileo 2.5.1's unchanged C control parser plus its Release accept checks.

Host/Linux only: uses small type/header and BSD strnstr shims. This does not
run the iOS app, networking, cache, APTWrapper or UIKit.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from build_repo import ROOT, SITE


def accepted(release):
    # RepoManager.swift, tag 2.5.1: architecture selection + Components guard.
    architectures = release.get('architectures', release.get('architecture', '')).split(' ')
    return 'iphoneos-arm64' in architectures and 'components' in release


def main():
    compiler = os.environ.get('CC') or shutil.which('clang')
    if not compiler:
        raise RuntimeError('clang is required to run the actual Sileo C parser')
    with tempfile.TemporaryDirectory(prefix='sileo-parser-') as directory:
        tmp = Path(directory)
        executable = tmp / 'parser'
        vendor = ROOT / 'tests/vendor/sileo-2.5.1'
        command = [compiler, '-fblocks', '-O1', '-Wno-nullability-completeness',
                   '-I', str(ROOT / 'tests/sileo_compat'), '-I', str(vendor),
                   str(vendor / 'ControlFileParserFast.c'), str(ROOT / 'tests/sileo_parser_driver.c'),
                   '-o', str(executable)]
        # The optional cross-toolchain override is only for the local Linux host.
        if os.environ.get('SILEO_TEST_TARGET'):
            command[1:1] = ['-target', os.environ['SILEO_TEST_TARGET']]
        subprocess.run(command, check=True)

        def parse(data, is_release):
            path = tmp / 'control'
            path.write_bytes(data)
            result = subprocess.run([str(executable), str(path), '1' if is_release else '0'],
                                    check=True, capture_output=True, text=True)
            return dict(json.loads(line) for line in result.stdout.splitlines())

        raw = (SITE / 'Release').read_bytes()
        release = parse(raw, True)
        if not accepted(release):
            raise ValueError('Sileo 2.5.1 rejects Release: missing Components or supported architecture')
        if release.get('origin') != 'Sentechtipsvn Tweak':
            raise ValueError('Sileo cannot read repository name')
        # Reproduce the exact metadata defect observed on the user's phone.
        without_components = b'\n'.join(line for line in raw.split(b'\n') if not line.startswith(b'Components:'))
        if accepted(parse(without_components, True)):
            raise ValueError('Missing-Components regression was not rejected')
        for field, algorithm in [('md5sum', 'md5'), ('sha256', 'sha256'), ('sha512', 'sha512')]:
            values = release.get(field, '')
            for name in ['Packages', 'Packages.gz', 'Packages.bz2', 'Packages.xz']:
                digest = hashlib.new(algorithm, (SITE / name).read_bytes()).hexdigest()
                # Same token/digest/filename match as RepoManager.isHashValid.
                if not any(len(parts := line.split()) >= 3 and parts[0] == digest and parts[2] == name
                           for line in values.split('\n')):
                    raise ValueError(f'Sileo cannot match {field} entry for {name}')
        packages = []
        for paragraph in (SITE / 'Packages').read_bytes().strip().split(b'\n\n'):
            entry = parse(paragraph + b'\n', False)
            for key in ['package', 'version', 'architecture', 'filename', 'size', 'sha256']:
                if not entry.get(key):
                    raise ValueError(f'Sileo package parser missing {key}')
            if entry['architecture'] != 'iphoneos-arm64':
                raise ValueError('Unsupported package architecture')
            packages.append(entry['package'])
        if set(packages) != {'vn.sentechtips.quickcontrol', 'vn.sentechtips.sharewifi', 'vn.sentechtips.senswipe'}:
            raise ValueError('Sileo parser did not read all three tweaks')
        print('PASS: actual Sileo 2.5.1 C parser; Release guards; missing-Components regression; 12 hash matches; 3 packages.')


if __name__ == '__main__':
    main()
