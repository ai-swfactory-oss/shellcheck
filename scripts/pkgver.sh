#!/usr/bin/env bash
# Prints the npm package version for upstream.json: the upstream version, or
# <version>-r.<repack> when this repository re-packs the same upstream release.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
jq -er 'if (.repack // 0) > 0 then "\(.version)-r.\(.repack)" else .version end' "$root/upstream.json"
