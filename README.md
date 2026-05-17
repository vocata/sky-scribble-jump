# Sky Scribble Jump

Sky Scribble Jump is a small Godot 4 vertical jumper inspired by classic doodle-style platform games. It uses original image-generated artwork, hand-tuned platform physics, spring boosts, launcher boosts, a start screen, and a dedicated game-over screen.

## Requirements

- Godot 4.6 or newer
- GNU Make for the convenience commands
- macOS only for the current export preset

## Run

```bash
make run
```

You can override the Godot executable when needed:

```bash
make run GODOT=/Applications/Godot.app/Contents/MacOS/Godot
```

## Useful Commands

```bash
make run           # Launch the game
make edit          # Open the project in the Godot editor
make check         # Start Godot headlessly for a quick project sanity check
make import        # Refresh Godot import metadata
make export-macos  # Build build/SkyScribbleJump.zip
make clean         # Remove local build output
```

For macOS distribution, `make export-macos` ad-hoc signs by default. For public distribution, sign with a Developer ID certificate and notarize the exported app:

```bash
make export-macos MACOS_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

## Controls

- `Start` button: begin a run
- `A` / `Left`: move left
- `D` / `Right`: move right
- Left mouse button: steer toward the pointer side
- `R`: restart during active gameplay
- `P`: pause or resume
- `Try Again` button: restart from the game-over screen

The player auto-jumps when landing on platforms and wraps through the left or right edge of the screen.

## Project Layout

- `assets/art/`: runtime artwork used by the game
- `scenes/`: Godot scenes, grouped by actors, gameplay, and UI
- `scripts/`: behavior code, grouped to mirror the scene folders
- `resources/`: editable Godot resources such as gameplay tuning values
- `release_notes/`: tagged release notes
- `docs/`: project documentation for contributors and publishing

## Assets

All runtime artwork in `assets/art/` was generated specifically for this project with image-generation tooling and then edited/cropped for use in Godot. Asset names use lowercase `snake_case` names without version suffixes.

See `docs/ASSETS.md` for the current asset inventory and naming rules.

## License

Sky Scribble Jump is released under the MIT License. See `LICENSE` for details.
