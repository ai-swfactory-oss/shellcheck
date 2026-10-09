#!/usr/bin/env bash
# Downloads the upstream ShellCheck release assets named in upstream.json,
# verifies each against its pinned sha256 digest and extracts it.
#
#   scripts/fetch.sh <outdir> [platform ...]     (default: every platform)
#
# Result: <outdir>/assets/<asset name>  (the original upstream archive)
#         <outdir>/<platform>/shellcheck, LICENSE.txt, README.txt
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
manifest="$root/upstream.json"
out=${1:?usage: fetch.sh <outdir> [platform ...]}
shift

if [ "$#" -gt 0 ]; then
  platforms=("$@")
else
  read -r -a platforms <<<"$(jq -r '.assets | keys | join(" ")' "$manifest")"
fi

version=$(jq -er .version "$manifest")

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

mkdir -p "$out/assets"
for platform in "${platforms[@]}"; do
  name=$(jq -er --arg p "$platform" '.assets[$p].name' "$manifest")
  digest=$(jq -er --arg p "$platform" '.assets[$p].digest' "$manifest")
  case "$digest" in
    sha256:*) expected=${digest#sha256:} ;;
    *) echo "fetch: $platform: digest '$digest' is not sha256:<hex>" >&2; exit 1 ;;
  esac

  archive="$out/assets/$name"
  url="https://github.com/koalaman/shellcheck/releases/download/v$version/$name"
  echo "fetch: $platform <- $url"
  curl -fsSL --retry 3 --retry-delay 5 -o "$archive" "$url"

  actual=$(sha256 "$archive")
  if [ "$actual" != "$expected" ]; then
    echo "fetch: $platform: sha256 mismatch for $name" >&2
    echo "  expected $expected" >&2
    echo "  actual   $actual" >&2
    rm -f "$archive"
    exit 1
  fi
  echo "fetch: $platform: sha256 $actual OK"

  dest="$out/$platform"
  rm -rf "$dest"
  mkdir -p "$dest"
  tar -xJf "$archive" -C "$dest" --strip-components=1
  for f in shellcheck LICENSE.txt; do
    if [ ! -f "$dest/$f" ]; then
      echo "fetch: $platform: $name has no $f at the expected place; archive contents:" >&2
      tar -tJf "$archive" >&2
      exit 1
    fi
  done
  chmod 755 "$dest/shellcheck"
done
