#!/usr/bin/env bash
#
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tgz=$(cd "${1:?usage: smoke.sh <tgzdir> <platform>}" && pwd)
platform=${2:?usage: smoke.sh <tgzdir> <platform>}
upstream=$(jq -er .version "$root/packages/shellcheck/upstream.json")
version=$(bash "$root/scripts/pkgver.sh")

thin="$tgz/ai-swfactory-oss-shellcheck-$version.tgz"
native="$tgz/ai-swfactory-oss-shellcheck-$platform-$version.tgz"

for f in "$thin" "$native"; do
  test -f "$f" || { echo "smoke: missing $f" >&2; exit 1; }
  if tar -xzOf "$f" package/package.json | jq -e '.scripts // {} | keys | any(test("install"))' >/dev/null; then
    echo "smoke: $f declares an install script" >&2; exit 1
  fi
done

work=$(mktemp -d)
cd "$work"
printf '{"name":"smoke","version":"1.0.0","private":true}\n' >package.json
npm install --no-audit --no-fund "$thin" "$native"

echo "== npm ls"
npm ls --all || true

bin="$work/node_modules/.bin/shellcheck"
native_bin="$work/node_modules/@ai-swfactory-oss/shellcheck-$platform/bin/shellcheck"
ls -l "$native_bin"
test -x "$native_bin" || { echo "smoke: $native_bin is not executable" >&2; exit 1; }

echo "== shellcheck --version"
"$bin" --version | tee version.out
grep -q "^version: $upstream\$" version.out || { echo "smoke: expected version $upstream" >&2; exit 1; }

echo "== upstreamVersion() and binaryPath()"
node --input-type=module -e '
  import fs from "node:fs";
  import { binaryPath, describeFailure, upstreamVersion } from "@ai-swfactory-oss/shellcheck";
  const expected = process.argv[1];
  const version = upstreamVersion();
  if (!version.ok) throw new Error(describeFailure(version.failure));
  if (version.value !== expected) throw new Error("upstreamVersion() " + version.value + " != " + expected);
  const located = binaryPath(process.platform, process.arch);
  if (!located.ok) throw new Error(describeFailure(located.failure));
  fs.accessSync(located.value, fs.constants.X_OK);
  console.log(version.value, located.value);
' "$upstream"

echo "smoke: $platform OK"
