#!/usr/bin/env python3
"""Build a flat, rootless APT source and Sileo native depictions. Stdlib only."""
import argparse
import bz2
import datetime
import gzip
import hashlib
import html
import json
import lzma
from pathlib import Path
import subprocess
from urllib.parse import quote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT


def parse_control(text):
    result = {}
    key = None
    for line in text.splitlines():
        if line.startswith((' ', '\t')):
            if key is None:
                raise ValueError('Continuation without field')
            result[key] += '\n' + line
        elif line:
            key, value = line.split(':', 1)
            if key in result:
                raise ValueError(f'Duplicate control field: {key}')
            result[key] = value.lstrip()
    return result


def run(*args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, text=True, **kwargs).stdout


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url', help='Asset/download URL for this deployment; Sileo always uses canonical_url')
    args = parser.parse_args()
    catalog = json.loads((ROOT / 'catalog.json').read_text())
    source_url = catalog['canonical_url'].rstrip('/') + '/'
    source_parts = urlsplit(source_url)
    if source_parts.scheme != 'https' or source_parts.query or source_parts.fragment or source_url != source_url.lower():
        raise ValueError('Sileo canonical source must be a lowercase HTTPS directory')
    base = (args.base_url or source_url).rstrip('/') + '/'
    parsed = urlsplit(base)
    if parsed.scheme != 'https' or parsed.query or parsed.fragment:
        raise ValueError('Base URL must be an HTTPS directory without query/fragment')
    (SITE / 'depictions').mkdir(parents=True, exist_ok=True)
    entries = catalog['packages']
    by_id = {e['package']: e for e in entries}
    if len(by_id) != len(entries):
        raise ValueError('Duplicate package ID in catalog')
    actual = list((SITE / 'debs').glob('*.deb'))
    if {p.name for p in actual} != {e['file'] for e in entries}:
        raise ValueError('Deb files and catalog differ; archive retired builds outside debs')
    scanned = run('dpkg-scanpackages', '--multiversion', 'debs', cwd=SITE)
    paragraphs = []
    public = []
    for paragraph in scanned.strip().split('\n\n'):
        fields = parse_control(paragraph)
        e = by_id[fields['Package']]
        if fields['Version'] != e['version'] or fields['Architecture'] != 'iphoneos-arm64':
            raise ValueError(f'Unexpected version/architecture: {e["name"]}')
        path = SITE / fields['Filename']
        if path.name != e['file']:
            raise ValueError('Catalog filename does not match actual deb')
        if 'firmware (>= 15.8.8)' not in fields.get('Depends', '') or 'firmware (<< 15.8.9)' not in fields['Depends']:
            raise ValueError('Missing supported firmware restriction')
        fields['Filename'] = './debs/' + path.name
        fields['Homepage'] = catalog['repository']
        fields['Icon'] = base + 'icons/' + e['icon']
        guide = catalog['repository'] + '/blob/master/projects/' + e['name'] + '/README.md'
        fields['Depiction'] = guide
        fields['SileoDepiction'] = base + 'depictions/' + e['slug'] + '.json'
        paragraphs.append('\n'.join(f'{k}: {v}' for k, v in fields.items()))
        description = e['summary'] + '\n\n' + '\n'.join('- ' + f for f in e['features'])
        depiction = {'class': 'DepictionTabView', 'minVersion': '0.4', 'tintColor': '#168A61', 'tabs': [
            {'class': 'DepictionStackView', 'tabname': 'Giới thiệu', 'views': [
                {'class': 'DepictionHeaderView', 'title': e['name']},
                {'class': 'DepictionMarkdownView', 'markdown': description},
                {'class': 'DepictionTableTextView', 'title': 'Phiên bản', 'text': e['version']},
                {'class': 'DepictionTableTextView', 'title': 'Thiết bị', 'text': 'iPhone 7 Plus'},
                {'class': 'DepictionTableTextView', 'title': 'Hệ điều hành', 'text': 'iOS 15.8.8'},
                {'class': 'DepictionTableTextView', 'title': 'Môi trường', 'text': 'Dopamine rootless · arm64'},
                {'class': 'DepictionSubheaderView', 'title': 'Trạng thái beta'},
                {'class': 'DepictionMarkdownView', 'markdown': e['status'] + '\n\nRespring sau khi cài. Không dành cho iPhone chưa jailbreak.'},
                {'class': 'DepictionTableButtonView', 'title': 'Hướng dẫn và mã nguồn', 'action': guide, 'openExternal': 1}
            ]},
            {'class': 'DepictionStackView', 'tabname': 'Thay đổi', 'views': [
                {'class': 'DepictionHeaderView', 'title': e['version']},
                {'class': 'DepictionMarkdownView', 'markdown': '\n'.join('- ' + c for c in e['changelog'])}
            ]}
        ]}
        (SITE / 'depictions' / (e['slug'] + '.json')).write_text(json.dumps(depiction, ensure_ascii=False, indent=2) + '\n')
        public.append({**e, 'url': base + 'debs/' + path.name, 'size': path.stat().st_size,
                       'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'guide': guide})
    packages = ('\n\n'.join(paragraphs) + '\n\n').encode()
    (SITE / 'Packages').write_bytes(packages)
    (SITE / 'Packages.gz').write_bytes(gzip.compress(packages, mtime=0))
    (SITE / 'Packages.bz2').write_bytes(bz2.compress(packages))
    (SITE / 'Packages.xz').write_bytes(lzma.compress(packages))
    date = datetime.datetime.now(datetime.timezone.utc).strftime('%a, %d %b %Y %H:%M:%S UTC')
    release = ['Origin: Sentechtipsvn Tweak', 'Label: Sentechtipsvn Tweak',
               'Suite: stable', 'Codename: sentechtipsvn', 'Version: 1.0', 'Components: main',
               'Architectures: iphoneos-arm64', 'Description: Personal rootless tweaks by Sentechtipsvn', 'Date: ' + date]
    index_names = ['Packages', 'Packages.gz', 'Packages.bz2', 'Packages.xz']
    for label, algorithm in [('MD5Sum', 'md5'), ('SHA256', 'sha256'), ('SHA512', 'sha512')]:
        release.append(label + ':')
        for name in index_names:
            data = (SITE / name).read_bytes()
            release.append(f' {hashlib.new(algorithm, data).hexdigest()} {len(data)} {name}')
    (SITE / 'Release').write_text('\n'.join(release) + '\n')
    (SITE / '.nojekyll').touch()
    (SITE / 'packages.json').write_text(json.dumps({'name': catalog['name'], 'source': source_url, 'packages': public}, ensure_ascii=False, indent=2) + '\n')
    esc = html.escape
    cards = ''
    for e in public:
        version = e['version'].replace('~beta', ' · beta ')
        cards += f'''<article class="card"><div class="card-top"><h2>{esc(e['name'])}</h2><a class="download" href="debs/{esc(e['file'])}" download aria-label="Tải xuống {esc(e['name'])}">Tải xuống</a></div><span class="version">{esc(version)}</span><p class="summary">{esc(e['summary'])}</p></article>'''
    (SITE / 'index.html').write_text(f'''<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light dark"><title>Sentechtipsvn Tweak</title><link rel="icon" href="CydiaIcon.png"><style>
:root{{--bg:#f2f7f4;--panel:#ffffffd9;--text:#16372c;--muted:#587268;--border:#146e491a;--green:#168a61;--blue:#007aff}}@media(prefers-color-scheme:dark){{:root{{--bg:#0b1712;--panel:#15271ff0;--text:#edf8f1;--muted:#a7bfb2;--border:#aadfc924;--green:#73dfaf;--blue:#0a84ff}}}}*{{box-sizing:border-box}}body{{margin:0;background:radial-gradient(ellipse at top right,#29956b16,transparent 65%),var(--bg);color:var(--text);font:14px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}}main{{max-width:720px;margin:auto;padding:32px 20px}}.brand{{display:flex;align-items:center;gap:12px}}.brand img{{width:42px;height:42px;border-radius:12px;flex:none}}.brand-copy{{min-width:0}}.brand-name{{margin:0;font-size:14px;font-weight:700;letter-spacing:.035em}}h1{{margin:3px 0 0;font-size:16px;line-height:1.45;font-weight:400;letter-spacing:0;color:var(--muted)}}.lead{{margin:18px 0 0;color:var(--muted);font-size:14px;max-width:580px}}.actions{{display:flex;gap:10px;flex-wrap:wrap;margin:18px 0 10px}}a{{color:var(--green);text-decoration:none}}a:hover{{text-decoration:underline}}.primary,button{{display:inline-flex;align-items:center;justify-content:center;min-height:42px;border:1px solid var(--border);border-radius:12px;padding:10px 16px;font:inherit;font-weight:600;cursor:pointer}}.primary{{background:#168a61;color:white}}button{{background:var(--panel);color:var(--text)}}.address{{display:block;overflow-wrap:anywhere;font-size:12px;line-height:1.6;color:var(--muted)}}#copied{{color:var(--green);font-size:12px;margin-top:6px}}#copied:empty{{display:none}}.grid{{display:grid;grid-template-columns:minmax(0,1fr);gap:10px;margin-top:24px}}.card{{min-width:0;padding:13px 16px 14px;background:var(--panel);border:1px solid var(--border);border-radius:18px;box-shadow:0 2px 10px #103d2603}}.card-top{{display:flex;align-items:center;justify-content:space-between;gap:12px}}h2{{min-width:0;margin:0;font-size:17px;line-height:1.3;font-weight:650;letter-spacing:-.015em;overflow-wrap:anywhere}}.download{{display:inline-flex;align-items:center;justify-content:center;flex:none;min-height:36px;padding:7px 13px;border:1px solid var(--blue);border-radius:11px;background:var(--blue);color:white;font-size:13px;line-height:20px;font-weight:600;white-space:nowrap}}.download:hover{{text-decoration:none;filter:brightness(.94)}}.download:focus-visible,button:focus-visible,.primary:focus-visible{{outline:3px solid #66b0ff;outline-offset:3px}}.version{{display:block;margin-top:0;color:var(--muted);font-size:12px;line-height:1.5}}.summary{{margin:7px 0 0;font-size:14px;line-height:1.5;color:var(--text)}}.note{{margin:20px 0 0;color:var(--muted);font-size:12px;line-height:1.6}}footer{{margin-top:24px;color:var(--muted);font-size:12px}}@media(max-width:540px){{main{{padding:24px 16px 28px}}}}@media(max-width:350px){{.brand-name{{font-size:12px}}.brand{{gap:10px}}.primary,button{{padding-inline:13px}}}}
</style></head><body><main><header><div class="brand"><img src="CydiaIcon.png" alt="" width="42" height="42"><div class="brand-copy"><p class="brand-name">SENTECHTIPSVN / TWEAKS</p><h1>Chiến hữu cũ. Tiện ích mới.</h1></div></div><p class="lead">Kho tweak cho iPhone 7 Plus · iOS 15.8.8 · Dopamine rootless.</p><div class="actions"><a class="primary" href="sileo://source/{esc(source_url)}">Thêm vào Sileo</a><button id="copy" type="button">Sao chép nguồn</button></div><code class="address" id="source">{esc(source_url)}</code><div id="copied" role="status"></div></header><section class="grid" aria-label="Danh sách tweak">{cards}</section><p class="note">Các gói đang ở giai đoạn beta. Xem chi tiết kiểm thử trong Sileo hoặc hướng dẫn trên GitHub. Respring sau khi cài.</p><footer>© Sentechtipsvn · <a href="{esc(catalog['repository'])}">GitHub &amp; hướng dẫn</a> · 3 tweak</footer></main><script>
document.getElementById('copy').addEventListener('click',async()=>{{const s=document.getElementById('source').textContent;try{{await navigator.clipboard.writeText(s);document.getElementById('copied').textContent='Đã sao chép nguồn. Mở Sileo → Nguồn → Thêm nguồn.';}}catch{{document.getElementById('copied').textContent='Nhấn giữ địa chỉ nguồn phía trên để sao chép.';}}}});
</script></body></html>''')
    print(f'Built {len(public)} packages for {base}')


if __name__ == '__main__':
    main()
