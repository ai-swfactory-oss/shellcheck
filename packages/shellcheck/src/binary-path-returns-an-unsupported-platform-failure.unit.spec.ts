import { expect, it } from 'vitest'

import { binaryPathOf } from './index'

const targets = ['linux-x64', 'linux-arm64', 'darwin-x64', 'darwin-arm64']

it('binaryPathOf returns a failure naming the platform for an os and cpu that no target in a targets literal covers, without throwing', () => {
  expect(() => binaryPathOf(targets, 'freebsd', 'riscv64')).not.toThrow()
  expect(binaryPathOf(targets, 'freebsd', 'riscv64')).toEqual({
    ok: false,
    failure: { kind: 'unsupported-platform', os: 'freebsd', cpu: 'riscv64', supported: targets },
  })
  expect(binaryPathOf(targets, 'win32', 'x64')).toEqual({
    ok: false,
    failure: { kind: 'unsupported-platform', os: 'win32', cpu: 'x64', supported: targets },
  })
})
