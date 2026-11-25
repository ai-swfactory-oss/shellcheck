import pin from './upstream.json' with { type: 'json' }
import { fail, type Result, succeed, supportedPlatformsOf, type UpstreamPinInvalid, upstreamVersionOf } from './upstream-pin'

export type { Result, UpstreamPinInvalid } from './upstream-pin'

const PIN_FILE = 'upstream.json'

const PREFIX = '@ai-swfactory-oss/shellcheck-'

const BIN_RELATIVE_PATH = 'bin/shellcheck'

export interface UnsupportedPlatform {
  readonly kind: 'unsupported-platform'
  readonly os: string
  readonly cpu: string
  readonly supported: readonly string[]
}

export interface BinaryLocation {
  readonly packageName: string
  readonly binRelativePath: string
}

export const upstreamVersion = (): Result<string, UpstreamPinInvalid> => upstreamVersionOf(pin, PIN_FILE)

export const supportedPlatforms = (): Result<readonly string[], UpstreamPinInvalid> => supportedPlatformsOf(pin, PIN_FILE)

export const platformPackage = (os: string, cpu: string): string => `${PREFIX}${os}-${cpu}`

export const binaryPathOf = (targets: readonly string[], os: string, cpu: string): Result<BinaryLocation, UnsupportedPlatform> =>
  targets.includes(`${os}-${cpu}`)
    ? succeed({ packageName: platformPackage(os, cpu), binRelativePath: BIN_RELATIVE_PATH })
    : fail({ kind: 'unsupported-platform', os, cpu, supported: targets })
