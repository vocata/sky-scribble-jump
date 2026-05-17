# Contributing

Thanks for taking a look at Sky Scribble Jump. This project is intentionally small, so changes should stay easy to read and easy to run locally.

## Local Workflow

1. Install Godot 4.6 or newer.
2. Run `make check` before opening a pull request.
3. Use `make run` for manual gameplay testing.
4. Use `make import` after adding or moving image assets.

## Code Style

- Keep gameplay code in `scripts/Main.gd` until a feature clearly needs its own module.
- Prefer small, direct changes over broad rewrites.
- Keep constants near the top of the script and name them by gameplay intent.
- Do not commit `.godot/`, `build/`, `.DS_Store`, or local export artifacts.

## Asset Rules

- Put runtime art under `assets/art/`.
- Use lowercase `snake_case` filenames.
- Do not add version suffixes such as `_v2`, `_final`, or `_new`.
- Place generated or edited runtime assets in the directory that matches their role.
- Run `make import` so Godot creates updated `.import` metadata.

## Releases

- Add a short markdown note under `release_notes/` for tagged releases.
- Keep macOS export versions in `export_presets.cfg` in sync with tagged releases.
- Public macOS builds should be Developer ID signed and notarized.
