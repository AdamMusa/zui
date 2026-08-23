# Music preview and fallback audio provenance

The live Nocturne queue streams official 30-second iTunes previews and presents a matching Apple
Music store link next to the player. Preview audio is streamed only: it is not committed, downloaded,
or intentionally cached by the application. The catalog entries were resolved through Apple's
iTunes Search API on 2026-08-23:

| Preview | Store page |
| --- | --- |
| Chris Brown — Residuals | https://music.apple.com/us/album/residuals/1740205873?i=1740206493&uo=4 |
| Chris Brown — Yo (Excuse Me Miss) | https://music.apple.com/us/album/yo-excuse-me-miss/323098604?i=323098607&uo=4 |
| Jordin Sparks & Chris Brown — No Air | https://music.apple.com/us/album/no-air/268314568?i=268314585&uo=4 |
| Chris Brown — Forever | https://music.apple.com/us/album/forever-main-version/282988493?i=282988494&uo=4 |

Preview audio and artwork are provided courtesy of iTunes and remain subject to Apple's terms.

## Bundled original fallbacks

The four OGG files in `assets/` are original procedural ambient loops generated for this repository
from layered sine synthesis, filtering, tremolo, echo, fades, and stereo placement with FFmpeg.
They have no external samples or third-party musical composition and ship under the repository's
MIT license.

| File | Duration |
| --- | ---: |
| `glass-horizon.ogg` | 48.96 s |
| `violet-transit.ogg` | 42.96 s |
| `afterimage.ogg` | 52.96 s |
| `midnight-drift.ogg` | 46.96 s |
