# shellcheck

[![update](https://github.com/ai-swfactory-oss/shellcheck/actions/workflows/update.yml/badge.svg)](https://github.com/ai-swfactory-oss/shellcheck/actions/workflows/update.yml)
[![build](https://github.com/ai-swfactory-oss/shellcheck/actions/workflows/build.yml/badge.svg)](https://github.com/ai-swfactory-oss/shellcheck/actions/workflows/build.yml)

[ShellCheck](https://github.com/koalaman/shellcheck) as npm packages: the **native upstream binary** per platform, updated and published automatically to GitHub Packages. No WASM, no download at install time, no install scripts.

| Package | What |
|---|---|
| `@ai-swfactory-oss/shellcheck` | Thin: the `shellcheck` bin and `binaryPath()` / `version` for Node. Depends optionally on the four platform packages, pinned exactly. |
| `@ai-swfactory-oss/shellcheck-linux-x64` | `bin/shellcheck` from upstream `shellcheck-v<ver>.linux.x86_64.tar.xz` |
| `@ai-swfactory-oss/shellcheck-linux-arm64` | `bin/shellcheck` from upstream `shellcheck-v<ver>.linux.aarch64.tar.xz` |
| `@ai-swfactory-oss/shellcheck-darwin-x64` | `bin/shellcheck` from upstream `shellcheck-v<ver>.darwin.x86_64.tar.xz` |
| `@ai-swfactory-oss/shellcheck-darwin-arm64` | `bin/shellcheck` from upstream `shellcheck-v<ver>.darwin.aarch64.tar.xz` |

npm installs only the platform package whose `os`/`cpu` match. The binaries are the unmodified upstream release assets, verified against the sha256 digests pinned in [`upstream.json`](upstream.json).

## Install

The packages live on GitHub Packages, which needs two things even for public packages.

1. The scope line, in your project's `.npmrc` (safe to commit; this repository commits the same one):

   ```
   @ai-swfactory-oss:registry=https://npm.pkg.github.com
   ```

2. A token with `read:packages` (a classic personal access token), in your **user** `~/.npmrc`, never in the repository:

   ```
   //npm.pkg.github.com/:_authToken=<token>
   ```

   In GitHub Actions, use `actions/setup-node` with `registry-url: https://npm.pkg.github.com`, `scope: "@ai-swfactory-oss"` and `NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}`, and grant the job `packages: read`.

Then:

```sh
npm install --save-dev @ai-swfactory-oss/shellcheck
npx shellcheck --version
npx shellcheck scripts/*.sh
```

From Node:

```js
const { binaryPath, version } = require('@ai-swfactory-oss/shellcheck');
spawnSync(binaryPath(), ['--format=json', 'script.sh']);
```

Installing with `--omit=optional` (or `--no-optional`) leaves no binary; `shellcheck` then says so and exits 1.

## Verify what you installed

The binaries are **upstream's release binaries, unmodified**: `scripts/fetch.sh` downloads each `.tar.xz` and refuses it unless its sha256 matches the digest pinned in [`upstream.json`](upstream.json), which comes from the GitHub API for the upstream release. Nothing is rebuilt.

On top of that, every publish run creates **GitHub build-provenance attestations** ([`actions/attest-build-provenance`](https://github.com/actions/attest-build-provenance), SLSA provenance signed through Sigstore) for each npm tarball and each `shellcheck` binary it publishes. An attestation binds the file's sha256 to this repository, the `build.yml` workflow, and the commit and run that packaged it. Verify with the [GitHub CLI](https://cli.github.com/) (logged in to github.com):

```sh
# the binary npm installed for you
gh attestation verify node_modules/@ai-swfactory-oss/shellcheck-linux-x64/bin/shellcheck \
  --repo ai-swfactory-oss/shellcheck \
  --signer-workflow ai-swfactory-oss/shellcheck/.github/workflows/build.yml

# a tarball, exactly as published (npm pack downloads it unchanged)
npm pack @ai-swfactory-oss/shellcheck-linux-x64@0.11.0
gh attestation verify ai-swfactory-oss-shellcheck-linux-x64-0.11.0.tgz --repo ai-swfactory-oss/shellcheck

# or any .tgz from the GitHub release
gh release download v0.11.0 --repo ai-swfactory-oss/shellcheck --pattern '*.tgz'
gh attestation verify ai-swfactory-oss-shellcheck-0.11.0.tgz --repo ai-swfactory-oss/shellcheck
```

To tie a binary back to upstream yourself: download the upstream archive named in the platform package's `NOTICE`, check its sha256 against the digest there, extract it, and compare its `shellcheck` with the installed one (`cmp`).

What the attestation does and does not say: it proves that this repository's `build.yml` produced (packaged) the file from the named commit. It does not say who compiled ShellCheck: upstream did, and the pinned digest is what ties the binary to upstream's release.

## Versions

- The package version **equals the ShellCheck version** (`0.11.0`), for all five packages.
- A **re-pack** of the same ShellCheck release (a packaging fix only, rare) is published as `<version>-r.<n>`, e.g. `0.11.0-r.1`, by setting `"repack": <n>` in `upstream.json`. Semver orders `0.11.0-r.1` *below* `0.11.0` (it is a prerelease), so the publish job always passes the explicit dist-tag `latest`: `npm install @ai-swfactory-oss/shellcheck` gets the re-pack, while a range like `^0.11.0` does not. Pin exactly (`@0.11.0-r.1`) if you need the re-pack under a range.
- Every published version has a GitHub release `v<package version>`.

## How it stays up to date (no maintenance)

| Workflow | When | What |
|---|---|---|
| `update` | Daily 04:23 UTC; keepalive on the 1st of each month | Reads `koalaman/shellcheck` `releases/latest` (never a prerelease). If it is newer than `upstream.json`, rewrites `upstream.json` with the `.tar.xz` asset names and the sha256 digests the GitHub API reports for them, and commits it as `github-actions[bot]`. Then, if the GitHub release `v<version>[-r.N]` is missing, runs `build` with publishing. A failed publish is retried the next day. The monthly run re-enables the workflow, so GitHub never disables the schedule for inactivity. |
| `build` | Push to `main` touching `upstream.json`, `scripts/`, `packages/`, `test/` or the workflow; manual; called by `update` | `scripts/fetch.sh` downloads the four assets and fails on any sha256 mismatch; `scripts/stage.sh` renders the packages; `npm pack` once. Each of `ubuntu-24.04`, `ubuntu-24.04-arm`, `macos-latest` and `macos-15-intel` installs the packed tarballs into a scratch project, checks `shellcheck --version`, lints a fixture (expects `SC2086`, exit 1) and a clean script (exit 0), and checks `binaryPath()`. Publishing (never on pull requests) attests build provenance for every tarball and binary, pushes the tested tarballs to GitHub Packages, platform packages first and the thin package last, skipping versions that already exist; then creates the release. |
| `pr` | Every pull request | `build` without publishing. |
| `failures` | After every `update` or `build` run on `main` | A failure opens one issue labelled `build-failure` (or comments on the open one); the next successful run closes it. |

A failing run publishes nothing new; the previous versions keep being served. Each release carries the npm tarballs as published, the original upstream archives, `shellcheck-<ver>-source.tar.gz` (the corresponding source, see below) and `SHA256SUMS` over all of them.

## Local build

```sh
bash scripts/fetch.sh build/upstream          # download + verify + extract
bash scripts/stage.sh build/upstream build/npm # render the packages
npm pack ./build/npm/shellcheck ./build/npm/shellcheck-*/ --pack-destination dist/tgz
bash scripts/smoke.sh dist/tgz darwin-arm64    # install and test like CI
```

Needs `bash`, `curl`, `jq`, `tar` with xz support, and Node.

## License

- The scripts and workflows in this repository are **MIT** (see [`LICENSE`](LICENSE)).
- The **npm packages are GPL-3.0-only**: the platform packages contain the ShellCheck binary, and ShellCheck is GPL-3.0 (Copyright Vidar Holen and contributors). Each package ships the upstream GPL-3.0 text as `LICENSE` and a `NOTICE`.
- Corresponding source (GPL-3.0 section 6): every GitHub release of this repository carries `shellcheck-<ver>-source.tar.gz`, the upstream source at tag `v<ver>`; it is also at https://github.com/koalaman/shellcheck.

This project is not affiliated with the ShellCheck project.
