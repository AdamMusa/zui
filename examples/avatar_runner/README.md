# Avatar Runner

A compact endless runner written entirely in Ruby with Zui. The example combines a retained
Canvas scene with application-owned physics, collision detection, scoring, scheduled updates,
keyboard focus, pointer input, and atomic reactive patches.

## Run

From this directory with the development checkout:

```bash
../../bin/zui run main.rb
```

Or with the installed gem:

```bash
zui run main.rb
```

## Controls

- `Space`, `Up`, or a click jumps.
- `Enter` starts or restarts a run.
- `Escape` pauses or resumes.
- `R` restarts immediately.

The game uses no browser layer, external game engine, application-owned QML, or image assets.
