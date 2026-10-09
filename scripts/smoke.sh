#!/usr/bin/env bash
# Installs the packed tarballs into a scratch project, as a consumer would,
# and checks that the installed `shellcheck` is the native upstream binary.
#
#   scripts/smoke.sh <tgzdir> <platform>      e.g. dist/tgz linux-x64
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tgz=$(cd "${1:?usage: smoke.sh <tgzdir> <platform>}" && pwd)
platform=${2:?usage: smoke.sh <tgzdir> <platform>}
upstream=$(jq -er .version "$root/upstream.json")
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

echo "== lint fixture (expect SC2086, exit 1)"
set +e
"$bin" "$root/test/fixture.sh" >lint.out 2>&1
rc=$?
set -e
cat lint.out
test "$rc" -eq 1 || { echo "smoke: expected exit 1, got $rc" >&2; exit 1; }
grep -q SC2086 lint.out || { echo "smoke: SC2086 not reported" >&2; exit 1; }

echo "== lint clean script (expect exit 0)"
"$bin" "$root/test/clean.sh"

echo "== require() API"
node -e '
  const sc = require("@ai-swfactory-oss/shellcheck");
  const fs = require("node:fs");
  if (sc.version !== process.argv[1]) throw new Error(`version ${sc.version} != ${process.argv[1]}`);
  fs.accessSync(sc.binaryPath(), fs.constants.X_OK);
  console.log(sc.version, sc.binaryPath());
' "$upstream"

echo "smoke: $platform OK"
