import { expect, it } from 'vitest'

import twoPlatformPin from './__fixtures__/two-platform-pin.json' with { type: 'json' }
import { supportedPlatformsOf } from './upstream-pin'

it('supportedPlatforms lists exactly the keys of upstream.json assets', () => {
  expect(supportedPlatformsOf(twoPlatformPin, 'upstream.json')).toEqual({
    ok: true,
    value: ['linux-x64', 'darwin-arm64'],
  })
})
