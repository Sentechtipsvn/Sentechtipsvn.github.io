#!/usr/bin/env python3
"""Verify indexes, all .deb bytes, depictions, and Release checksums."""
import bz2
import gzip
import hashlib
from html.parser import HTMLParser
import json
import lzma
from pathlib import Path
import subprocess
from urllib.parse import urlsplit
from build_repo import ROOT, SITE, parse_control


def check(ok, message):
    if not ok:
        raise ValueError(message)


class SourceLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.source = ''
        self.in_source = False
        self.add_links = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'code' and attrs.get('id') == 'source':
            self.in_source = True
        if tag == 'a' and attrs.get('href', '').startswith('sileo://source/'):
            self.add_links.append(attrs['href'])

    def handle_endtag(self, tag):
        if tag == 'code':
            self.in_source = False

    def handle_data(self, data):
        if self.in_source:
            self.source += data


def main():
    catalog = json.loads((ROOT / 'catalog.json').read_text())
    canonical = catalog['canonical_url'].rstrip('/') + '/'
    page = SourceLinks()
    page.feed((SITE / 'index.html').read_text())
    check(canonical == canonical.lower(), 'Sileo source must survive URL lowercasing')
    check(page.source == canonical, 'Copy source address must use canonical_url, not Pages base URL')
    check(page.add_links == ['sileo://source/' + canonical], 'Add to Sileo must use canonical_url')
    data = (SITE / 'Packages').read_bytes()
    for name, decode in [('Packages.gz', gzip.decompress), ('Packages.bz2', bz2.decompress), ('Packages.xz', lzma.decompress)]:
        check(decode((SITE / name).read_bytes()) == data, f'Compressed index differs: {name}')
    seen = set()
    public = json.loads((SITE / 'packages.json').read_text())
    check(public['source'] == canonical, 'Public source metadata must use canonical_url')
    for paragraph in data.decode().strip().split('\n\n'):
        entry = parse_control(paragraph)
        key = entry['Package'], entry['Version'], entry['Architecture']
        check(key not in seen, 'Duplicate package/version/architecture')
        seen.add(key)
        relative = entry['Filename']
        check(relative.startswith('./debs/') and '..' not in Path(relative).parts, 'Invalid package filename')
        path = SITE / relative
        raw = path.read_bytes()
        check(len(raw) == int(entry['Size']), 'Deb size mismatch')
        for field, alg in [('MD5sum', 'md5'), ('SHA1', 'sha1'), ('SHA256', 'sha256')]:
            check(hashlib.new(alg, raw).hexdigest() == entry[field], f'Deb {field} mismatch')
        control = parse_control(subprocess.run(['dpkg-deb', '-f', str(path)], check=True, capture_output=True, text=True).stdout)
        for field in ['Package', 'Version', 'Architecture', 'Depends']:
            check(control[field] == entry[field], f'Index overrides actual {field}')
        check(entry['Architecture'] == 'iphoneos-arm64', 'Unexpected architecture')
        depiction_path = SITE / 'depictions' / Path(urlsplit(entry['SileoDepiction']).path).name
        depiction = json.loads(depiction_path.read_text())
        check(depiction['class'] == 'DepictionTabView' and len(depiction['tabs']) == 2, 'Invalid native depiction')
        check((SITE / 'icons' / Path(urlsplit(entry['Icon']).path).name).is_file(), 'Missing icon')
    check(len(seen) == len(public['packages']) == 3, 'Expected exactly three current tweaks')
    release = parse_control((SITE / 'Release').read_text())
    check(release['Architectures'] == 'iphoneos-arm64', 'Wrong Release architecture')
    check('Components' in release and release['Components'].strip() == 'main', 'Sileo 2.5.1 requires Components in Release')
    check(release.get('Origin') == 'Sentechtipsvn Tweak', 'Missing repository display name')
    for field, alg in [('MD5Sum', 'md5'), ('SHA256', 'sha256'), ('SHA512', 'sha512')]:
        for line in release[field].strip().splitlines():
            digest, size, name = line.split()
            raw = (SITE / name).read_bytes()
            check(len(raw) == int(size) and hashlib.new(alg, raw).hexdigest() == digest, f'Release checksum mismatch: {name}')
    print('PASS: 3 package identities/versions, .deb bytes, native depictions, icons, compressed indexes, Release hashes.')


if __name__ == '__main__':
    main()
