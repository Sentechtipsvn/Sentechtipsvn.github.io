#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$project_dir/build/tests"
common=(-std=c11 -Wall -Wextra -Werror -fsanitize=address,undefined -fno-omit-frame-pointer -I "$project_dir/Sources")
for name in arp method_abi profile; do
    sources=("$project_dir/tests/${name}_test.c")
    if [ "$name" = arp ]; then sources+=("$project_dir/Sources/SWArp.c"); fi
    gcc "${common[@]}" "${sources[@]}" -o "$project_dir/build/tests/${name}_test"
    ASAN_OPTIONS=detect_leaks=0 "$project_dir/build/tests/${name}_test"
done
