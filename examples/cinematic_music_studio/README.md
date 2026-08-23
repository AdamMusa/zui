# Nocturne

A cinematic spatial-music and mastering studio written entirely in Ruby. Its native Qt Multimedia
transport streams four official 30-second Apple/iTunes previews featuring Chris Brown, with remote
album artwork, real seeking, play/pause, cyclic previous/next, end-of-track advance, and a store link
for every selection. The previews are streamed only and the app does not download or cache the audio.
The padded queue rows use smooth lift, movement, and settle feedback while selecting/reordering.
It also combines mixer sliders, signal-chain switches, particles, mastering state, and an
image-backed mastering dialog.

Preview audio and artwork are provided courtesy of iTunes. An internet connection is required.

```bash
zui run main.rb
```
