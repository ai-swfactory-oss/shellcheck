import { expect, it } from 'vitest'

import noAssetsPin from './__fixtures__/no-assets-pin.json' with { type: 'json' }
import repackedVersionPin from './__fixtures__/repacked-version-pin.json' with { type: 'json' }
import twoPlatformPin from './__fixtures__/two-platform-pin.json' with { type: 'json' }
import { upstreamVersionOf } from './upstream-pin'

const refused = (reason: string): unknown => ({
  ok: false,
  failure: { kind: 'upstream-pin-invalid', file: 'upstream.json', reason },
})

it('the upstream version is read from upstream.json, and a missing or invalid pin is refused as data naming the file', () => {
  expect(upstreamVersionOf(twoPlatformPin, 'upstream.json')).toEqual({ ok: true, value: '1.2.3' })
  expect(upstreamVersionOf(undefined, 'upstream.json')).toEqual(refused('is missing'))
  expect(upstreamVersionOf([], 'upstream.json')).toEqual(refused('is not a JSON object'))
  expect(upstreamVersionOf(repackedVersionPin, 'upstream.json')).toEqual(refused('pins no version of the form <major>.<minor>.<patch>'))
  expect(upstreamVersionOf(noAssetsPin, 'upstream.json')).toEqual(refused('pins no assets'))
})
