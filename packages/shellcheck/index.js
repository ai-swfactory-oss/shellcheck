'use strict';

const path = require('node:path');

const pkg = require('./package.json');

/** The ShellCheck version this package runs (the upstream version, without any -r.N re-pack suffix). */
const version = pkg.version.replace(/-r\.\d+$/, '');

/** Name of the platform package that carries the binary for this process. */
function platformPackage(platform = process.platform, arch = process.arch) {
  return `@ai-swfactory-oss/shellcheck-${platform}-${arch}`;
}

/** Absolute path of the native shellcheck binary for this platform. Throws if it is not installed. */
function binaryPath() {
  const name = platformPackage();
  let dir;
  try {
    dir = path.dirname(require.resolve(`${name}/package.json`));
  } catch {
    const supported = Object.keys(pkg.optionalDependencies || {})
      .map((n) => n.replace('@ai-swfactory-oss/shellcheck-', ''))
      .join(', ');
    throw new Error(
      `@ai-swfactory-oss/shellcheck: ${name} is not installed. ` +
        `Supported platforms: ${supported}. ` +
        'If yours is one of them, reinstall without --omit=optional / --no-optional.'
    );
  }
  return path.join(dir, 'bin', 'shellcheck');
}

module.exports = { binaryPath, version };
