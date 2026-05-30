# Asset Inventory

Runtime assets live in `assets/art/`. The game should not reference temporary source images, generated prompts, or editing intermediates.

## Naming Rules

- Use lowercase `snake_case`.
- Name assets by role first, then variant when useful.
- Avoid version suffixes like `_v2`, `_v4`, `_new`, or `_final`.
- Keep file paths stable once they are referenced from scripts or scenes.

## Runtime Assets

| Path | Purpose |
| --- | --- |
| `assets/art/backgrounds/gameplay_background.png` | Gameplay notebook background |
| `assets/art/characters/player.png` | Player character |
| `assets/art/characters/player_fire_boots_flame_short.png` | Player fire-boots boost frame with shorter flame jets |
| `assets/art/characters/player_fire_boots_flame_long.png` | Player fire-boots boost frame with longer flame jets |
| `assets/art/effects/sparkle.png` | Burst particle sprite |
| `assets/art/platforms/platform_green.png` | Normal platform |
| `assets/art/platforms/platform_blue_moving.png` | Moving platform |
| `assets/art/platforms/platform_red_fragile.png` | Fragile platform |
| `assets/art/props/spring.png` | Spring boost prop |
| `assets/art/props/launcher.png` | Launcher boost prop |
| `assets/art/props/fire_boots.png` | Fire-boots pickup prop |
| `assets/art/screens/start_screen.png` | Start screen background |
| `assets/art/screens/game_over_screen.png` | Game-over screen background |
| `assets/art/ui/button_start.png` | Start button art |
| `assets/art/ui/button_retry.png` | Retry button art |
| `assets/art/ui/panel_game_over.png` | Game-over score panel |

## Adding Assets

1. Generate or edit the image outside Godot.
2. Crop it to the smallest practical runtime dimensions.
3. Save it under the matching `assets/art/` folder.
4. Reference the new path from scripts or scenes.
5. Run `make import` and commit the generated `.import` file.
