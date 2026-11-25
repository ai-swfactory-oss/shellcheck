#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
jq -er 'if (.repack // 0) > 0 then "\(.version)-r.\(.repack)" else .version end' "$root/packages/shellcheck/src/upstream.json"
