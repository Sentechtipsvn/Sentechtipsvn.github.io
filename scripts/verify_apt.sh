#!/usr/bin/env bash
# Consume the flat index with APT in a temporary state directory; never install.
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d)"
trap 'rm -rf "$check_dir"' EXIT
chmod 755 "$check_dir"
mkdir -p "$check_dir/lists/partial" "$check_dir/cache/archives/partial"
printf 'deb [trusted=yes arch=iphoneos-arm64] file:%s ./\n' "$project_dir" > "$check_dir/sources.list"
options=(-o "Dir::Etc::sourcelist=$check_dir/sources.list" -o Dir::Etc::sourceparts=-
    -o "Dir::State::lists=$check_dir/lists" -o "Dir::Cache=$check_dir/cache"
    -o Dir::Etc::parts=- -o Dir::Etc::main=- -o APT::Architecture=iphoneos-arm64 -o Debug::NoLocking=1 -o APT::Get::List-Cleanup=0)
apt-get "${options[@]}" update > "$check_dir/update.log" 2>&1 || { cat "$check_dir/update.log"; exit 1; }
for id in vn.sentechtips.senswipe vn.sentechtips.sharewifi vn.sentechtips.quickcontrol; do
    apt-cache "${options[@]}" show "$id" > "$check_dir/package"
    test -s "$check_dir/package"
    printf 'APT index read OK: %s\n' "$id"
done
