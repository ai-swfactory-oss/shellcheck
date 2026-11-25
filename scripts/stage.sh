#!/usr/bin/env bash
#
#
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
package="$root/packages/shellcheck"
manifest="$package/src/upstream.json"
fetched=${1:?usage: stage.sh <fetchdir> <outdir>}
out=${2:?usage: stage.sh <fetchdir> <outdir>}

scope=@ai-swfactory-oss
repo_url=https://github.com/ai-swfactory-oss/shellcheck.git
upstream=$(jq -er .version "$manifest")
version=$(bash "$root/scripts/pkgver.sh")
read -r -a platforms <<<"$(jq -r '.assets | keys | join(" ")' "$manifest")"

common='{
  author: "ai-swfactory",
  homepage: "https://github.com/ai-swfactory-oss/shellcheck#readme",
  bugs: { url: "https://github.com/ai-swfactory-oss/shellcheck/issues" },
  repository: { type: "git", url: $repo },
  publishConfig: { registry: "https://npm.pkg.github.com" }
}'

notice() {
  cat "$root/packages/NOTICE.in"
  printf '\nThis package: %s %s, re-packaged from ShellCheck v%s.\n' "$1" "$version" "$upstream"
  printf 'Upstream release: https://github.com/koalaman/shellcheck/releases/tag/v%s\n' "$upstream"
  printf 'Corresponding source (GPL-3.0 section 6): shellcheck-%s-source.tar.gz on\n' "$upstream"
  printf 'https://github.com/ai-swfactory-oss/shellcheck/releases/tag/v%s\n' "$version"
  printf 'and https://github.com/koalaman/shellcheck/tree/v%s\n\n' "$upstream"
  printf '%s\n' "$2"
}

rm -rf "$out"
mkdir -p "$out"

optional='{}'
for platform in "${platforms[@]}"; do
  os=${platform%%-*}
  cpu=${platform#*-}
  name="$scope/shellcheck-$platform"
  asset=$(jq -er --arg p "$platform" '.assets[$p].name' "$manifest")
  digest=$(jq -er --arg p "$platform" '.assets[$p].digest' "$manifest")
  dir="$out/shellcheck-$platform"

  mkdir -p "$dir/bin"
  cp "$fetched/$platform/shellcheck" "$dir/bin/shellcheck"
  chmod 755 "$dir/bin/shellcheck"
  cp "$fetched/$platform/LICENSE.txt" "$dir/LICENSE"
  notice "$name" "Binary: bin/shellcheck, unmodified from upstream asset $asset ($digest)." >"$dir/NOTICE"
  {
    printf '# %s\n\n' "$name"
    printf 'The native [ShellCheck](https://github.com/koalaman/shellcheck) v%s binary for `%s` / `%s`.\n\n' "$upstream" "$os" "$cpu"
    printf 'Do not install this package directly: install [`%s/shellcheck`](https://github.com/ai-swfactory-oss/shellcheck), which depends on it optionally and runs it.\n\n' "$scope"
    printf 'The binary is the unmodified upstream release asset `%s` (`%s`).\n\n' "$asset" "$digest"
    printf 'Provenance: `gh attestation verify bin/shellcheck --repo ai-swfactory-oss/shellcheck` (run in this package directory).\n\n'
    printf 'License: GPL-3.0-only (see `LICENSE` and `NOTICE`).\n'
  } >"$dir/README.md"

  jq -n --arg name "$name" --arg version "$version" --arg upstream "$upstream" \
    --arg os "$os" --arg cpu "$cpu" --arg repo "$repo_url" \
    "{
      name: \$name,
      version: \$version,
      description: \"ShellCheck \(\$upstream) native binary for \(\$os)-\(\$cpu) (used by @ai-swfactory-oss/shellcheck)\",
      keywords: [\"shellcheck\", \"shell\", \"lint\"],
      license: \"GPL-3.0-only\",
      os: [\$os],
      cpu: [\$cpu],
      files: [\"bin/shellcheck\", \"LICENSE\", \"NOTICE\", \"README.md\"],
      preferUnplugged: true
    } + $common" >"$dir/package.json"

  optional=$(jq -c --arg n "$name" --arg v "$version" '. + {($n): $v}' <<<"$optional")
done

built="$package/dist"
test -f "$built/index.js" || { echo "stage: $built/index.js is missing: build packages/shellcheck first" >&2; exit 1; }
thin="$out/shellcheck"
mkdir -p "$thin"
cp -R "$built" "$thin/dist"
cp "$package/README.md" "$thin/README.md"
cp "$fetched/${platforms[0]}/LICENSE.txt" "$thin/LICENSE"
notice "$scope/shellcheck" "This package holds no binary: it runs the one from $scope/shellcheck-<platform>-<arch>." >"$thin/NOTICE"
jq --arg version "$version" --arg repo "$repo_url" --argjson optional "$optional" \
  ". + {version: \$version, optionalDependencies: \$optional} + $common" \
  "$package/package.json" >"$thin/package.json"

echo "stage: $version ($upstream) -> $out"
ls -1 "$out"
