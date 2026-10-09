# @ai-swfactory-oss/shellcheck

[ShellCheck](https://github.com/koalaman/shellcheck), the static analysis tool for shell scripts, as an npm package that runs the **native upstream binary** for your platform (no WASM, no download at install time, no install scripts).

Platforms: `linux-x64`, `linux-arm64`, `darwin-x64`, `darwin-arm64`. The binary comes from the matching optional dependency `@ai-swfactory-oss/shellcheck-<platform>-<arch>`, which is the unmodified upstream release asset, verified against its sha256 digest.

## Install

The packages are on GitHub Packages. Point the scope at it (in your project's `.npmrc`):

```
@ai-swfactory-oss:registry=https://npm.pkg.github.com
```

GitHub Packages requires a token even for public packages: a classic personal access token with `read:packages`, in your user `~/.npmrc` (never commit it):

```
//npm.pkg.github.com/:_authToken=<token>
```

In GitHub Actions, `actions/setup-node` with `registry-url: https://npm.pkg.github.com` and `NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` does this (the workflow needs `packages: read`).

```sh
npm install --save-dev @ai-swfactory-oss/shellcheck
npx shellcheck --version
```

## Use

```sh
shellcheck script.sh
```

From Node:

```js
const { binaryPath, version } = require('@ai-swfactory-oss/shellcheck');
// binaryPath(): absolute path to the native shellcheck binary
// version: the ShellCheck version, e.g. "0.11.0"
```

## Verify

Every published tarball and binary has a GitHub build-provenance attestation:

```sh
gh attestation verify node_modules/@ai-swfactory-oss/shellcheck-linux-x64/bin/shellcheck \
  --repo ai-swfactory-oss/shellcheck
```

The binary itself is upstream's release binary, unmodified, its archive's sha256 pinned (see `NOTICE` in the platform package). Details: https://github.com/ai-swfactory-oss/shellcheck#verify-what-you-installed

## Versions

The package version equals the ShellCheck version. A rare re-pack of the same ShellCheck release (packaging fix only) is published as `<version>-r.<n>` with the `latest` dist-tag.

## License

GPL-3.0-only, because the packages contain (or run) ShellCheck, which is GPL-3.0. See `LICENSE` and `NOTICE`. Source: https://github.com/ai-swfactory-oss/shellcheck/releases
