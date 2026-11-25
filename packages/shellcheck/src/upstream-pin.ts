const SEMVER = /^\d+\.\d+\.\d+$/

export type Result<T, F> = { readonly ok: true; readonly value: T } | { readonly ok: false; readonly failure: F }

interface UpstreamPin {
  readonly version: string
  readonly platforms: readonly string[]
}

export interface UpstreamPinInvalid {
  readonly kind: 'upstream-pin-invalid'
  readonly file: string
  readonly reason: string
}

export const succeed = <T>(value: T): { readonly ok: true; readonly value: T } => ({ ok: true, value })

export const fail = <F>(failure: F): { readonly ok: false; readonly failure: F } => ({ ok: false, failure })

const isRecord = (value: unknown): value is Readonly<Record<string, unknown>> =>
  typeof value === 'object' && value !== null && !Array.isArray(value)

const invalid = (file: string, reason: string): UpstreamPinInvalid => ({ kind: 'upstream-pin-invalid', file, reason })

const parseUpstreamPin = (data: unknown, file: string): Result<UpstreamPin, UpstreamPinInvalid> => {
  if (data === undefined) return fail(invalid(file, 'is missing'))
  if (!isRecord(data)) return fail(invalid(file, 'is not a JSON object'))
  const version = data.version
  if (typeof version !== 'string' || !SEMVER.test(version)) {
    return fail(invalid(file, 'pins no version of the form <major>.<minor>.<patch>'))
  }
  const assets = data.assets
  if (!isRecord(assets) || Object.keys(assets).length === 0) return fail(invalid(file, 'pins no assets'))
  return succeed({ version, platforms: Object.keys(assets) })
}

export const upstreamVersionOf = (data: unknown, file: string): Result<string, UpstreamPinInvalid> => {
  const pin = parseUpstreamPin(data, file)
  return pin.ok ? succeed(pin.value.version) : pin
}

export const supportedPlatformsOf = (data: unknown, file: string): Result<readonly string[], UpstreamPinInvalid> => {
  const pin = parseUpstreamPin(data, file)
  return pin.ok ? succeed(pin.value.platforms) : pin
}
