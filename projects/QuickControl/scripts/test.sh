#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$project_dir/build/tests"
gcc -std=c11 -Wall -Wextra -Werror -fsanitize=address,undefined -fno-omit-frame-pointer \
    -I "$project_dir/Sources" "$project_dir/tests/policy_test.c" -lm -o "$project_dir/build/tests/policy_test"
ASAN_OPTIONS=detect_leaks=0 "$project_dir/build/tests/policy_test"
