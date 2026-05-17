# Testing

Use this checklist before releases, gameplay tuning changes, or export changes.

## Quick Checks

```bash
make import
make check
```

## Gameplay Smoke Test

Run the game with:

```bash
make run
```

Check these flows:

- Start screen appears first, and gameplay starts only after clicking `Start`.
- Player moves left and right with `A` / `D` and arrow keys.
- Holding a direction increases horizontal speed over time.
- Player wraps cleanly through the left and right screen edges.
- Normal green platforms bounce the player consistently.
- Moving blue platforms move horizontally and still bounce correctly.
- Fragile red platforms break after landing while preserving the normal jump height.
- Springs visibly compress when landed on, then launch the player higher.
- Launchers pull the player inside, charge, and fire the player upward.
- Score increases while climbing and best score updates after failure.
- Game Over screen blocks accidental restart from random clicks.
- `Try Again` button restarts the run and shows its pressed animation.
- `P` pauses and resumes during active gameplay.
- `R` restarts during active gameplay but does not bypass the Game Over retry button.

## Export Check

```bash
make export-macos
unzip -t build/SkyScribbleJump.zip
```

Then manually unzip and launch `Sky Scribble Jump.app`.

For public macOS distribution, ad-hoc signing is not enough. Use a Developer ID Application certificate and notarize the build.

## Visual Regression Pass

After adding or replacing artwork, inspect:

- Start screen composition at `480x720`.
- Gameplay background scaling.
- Platform thickness across green, blue, and red platforms.
- Spring and launcher seating on platforms.
- Game Over text readability.
- Button hit areas and pressed animations.
