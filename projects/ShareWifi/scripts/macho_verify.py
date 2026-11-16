#!/usr/bin/env python3
"""Validate Mach-O architecture, deployment target and ad-hoc code hashes.

This checks an archive on the build host. It does NOT test SpringBoard behavior.
"""
import hashlib
import json
import math
import plistlib
from pathlib import Path
import struct
import subprocess
import sys
import tempfile


def check(condition, message):
    if not condition:
        raise ValueError(message)


def verify_macho(path, expected_type):
    data = path.read_bytes()
    header = struct.unpack_from('<8I', data)
    check(header[0] == 0xfeedfacf, f'{path.name}: not thin Mach-O 64')
    check(header[1] == 0x100000c, f'{path.name}: not arm64')
    check(header[3] == expected_type, f'{path.name}: wrong Mach-O file type')
    cursor, signature, minimum, platform, dependencies, rpaths = 32, None, None, None, [], []
    for _ in range(header[4]):
        cmd, length = struct.unpack_from('<II', data, cursor)
        check(length >= 8 and cursor + length <= len(data), 'invalid load command')
        if cmd == 0x1d:
            signature = struct.unpack_from('<II', data, cursor + 8)
        elif cmd == 0x32:
            platform, minimum = struct.unpack_from('<II', data, cursor + 8)
        elif cmd == 0x25:
            minimum = struct.unpack_from('<I', data, cursor + 8)[0]
            platform = 2
        elif cmd in (0xc, 0x80000018, 0x8000001f):
            offset = struct.unpack_from('<I', data, cursor + 8)[0]
            dependencies.append(data[cursor + offset:cursor + length].split(b'\0')[0].decode())
        elif cmd == 0x8000001c:
            offset = struct.unpack_from('<I', data, cursor + 8)[0]
            rpaths.append(data[cursor + offset:cursor + length].split(b'\0')[0].decode())
        cursor += length
    check(platform == 2 and minimum == 0x000f0000, 'expected iOS 15.0 deployment target')
    check(signature is not None, f'{path.name}: missing code signature')
    start, size = signature
    check(start + size <= len(data), 'code signature out of bounds')
    magic, total_length, count = struct.unpack_from('>III', data, start)
    check(magic == 0xfade0cc0 and total_length <= size, 'invalid signature superblob')
    checked_directories = 0
    for i in range(count):
        _, blob_offset = struct.unpack_from('>II', data, start + 12 + i * 8)
        pos = start + blob_offset
        blob_magic, blob_length = struct.unpack_from('>II', data, pos)
        check(blob_offset + blob_length <= total_length, 'signature blob out of bounds')
        if blob_magic != 0xfade0c02:
            continue
        fields = struct.unpack_from('>9I4B', data, pos)
        _, _, _, flags, hash_offset, _, _, slots, limit, hash_size, hash_type, _, page_shift = fields
        check(flags & 2, 'expected ad-hoc signature')
        check(0 < page_shift <= 16 and limit <= start, 'invalid CodeDirectory limits')
        check(slots == math.ceil(limit / (1 << page_shift)), 'invalid code-slot count')
        check(hash_offset + slots * hash_size <= blob_length, 'code hashes out of bounds')
        algorithm = {1: 'sha1', 2: 'sha256', 3: 'sha256', 4: 'sha384'}.get(hash_type)
        check(algorithm is not None, 'unsupported code hash')
        for page in range(slots):
            first = page * (1 << page_shift)
            digest = hashlib.new(algorithm, data[first:min(first + (1 << page_shift), limit)]).digest()[:hash_size]
            stored = data[pos + hash_offset + page * hash_size:pos + hash_offset + (page + 1) * hash_size]
            check(digest == stored, f'{path.name}: invalid code hash on page {page}')
        checked_directories += 1
    check(checked_directories > 0, 'no CodeDirectory verified')
    check(all(x.startswith(('/usr/lib/', '/System/Library/', '@rpath/')) for x in dependencies),
          'unexpected build-host or rootful dependency')
    return {'architecture': 'arm64', 'minimum_ios': '15.0',
            'verified_code_directories': checked_directories,
            'dependencies': dependencies, 'rpaths': rpaths}

