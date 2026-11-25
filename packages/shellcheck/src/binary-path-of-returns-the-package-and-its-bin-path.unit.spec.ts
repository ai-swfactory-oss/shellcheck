import { expect, it } from 'vitest'

import { binaryPathOf } from './index'

const targets = ['linux-x64', 'linux-arm64', 'darwin-x64', 'darwin-arm64']

it('binaryPathOf returns packageName and binRelativePath bin/shellcheck for a declared platform, and no host path', () => {
  expect(binaryPathOf(targets, 'darwin', 'arm64')).toEqual({
    ok: true,
    value: { packageName: '@ai-swfactory-oss/shellcheck-darwin-arm64', binRelativePath: 'bin/shellcheck' },
  })
  expect(binaryPathOf(targets, 'linux', 'x64')).toEqual({
    ok: true,
    value: { packageName: '@ai-swfactory-oss/shellcheck-linux-x64', binRelativePath: 'bin/shellcheck' },
  })
})
