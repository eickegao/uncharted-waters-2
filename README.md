# Uncharted Waters: New Horizons

![tests](https://github.com/JohanLi/uncharted-waters-2/actions/workflows/tests.yml/badge.svg?branch=main)

[Uncharted Waters: New Horizons](https://en.wikipedia.org/wiki/Uncharted_Waters#Uncharted_Waters:_New_Horizons)
(大航海時代II) is an open world RPG and simulation game from 1994, set during
the Age of Exploration. Being the favorite game of my childhood, I’m remaking
it, originally with web technologies and now with the
[Defold](https://defold.com) game engine.

This is not meant to be even close to a full remake. I’m a web developer
transitioning to doing consulting work — this side project lets prospective
employers see my code.

<p align="center">
  <img src=".github/readme/uncharted-waters-2.png" alt="Uncharted Waters: New Horizons">
  Screenshots of the original game
</p>

## Features

- Walking around in any of the 130 ports and entering their buildings.
- Sailing around the world map, where your speed takes into account all the
  factors of the original game.
- The opening story in Lisbon, the Pub, Shipyard (used ships), Harbor
  (supplies), Lodge, Bank, Item Shop and Church.

#### Next up on the roadmap

- Markets
  - Trade goods, taking into account price indices.
- Shipyards
  - Remodel ships.

## Running the game

The images and music are stored with [Git LFS](https://git-lfs.com), so make
sure it's installed before cloning (or run `git lfs pull` afterwards).

1. Install the [Defold editor](https://defold.com/download/).
2. Open `game.project` in the editor.
3. Choose **Project → Build** (Ctrl/Cmd + B).

To build from the command line, use
[bob.jar](https://defold.com/manuals/bob/):

```sh
java -jar bob.jar --platform x86_64-linux build
```

HTML5, Windows, macOS and Linux bundles are made through
**Project → Bundle** in the editor.

#### Controls

- **WASD** movement
- **E**, **Enter** or **left-click** confirm, select
- **Escape** or **right-click** cancel, exit
- **E** at sea, next to a port, to dock

## 中文说明

这是《大航海时代II》的重制版，最初用 TypeScript + React 编写，现已移植到
[Defold](https://defold.com) 引擎（Lua）。安装 Git LFS 并克隆仓库后，用 Defold
编辑器打开 `game.project` 即可运行。游戏逻辑在 `modules/`，界面由
`modules/ui/` 用 Lua 动态生成 GUI 节点，单元测试在 `tests/`。

## Project structure

```
game.project            Defold project settings
main/                   main collection, game loop and GUI scripts
modules/                game logic in plain Lua (no Defold APIs except
                        sys.load_resource), shared by all scripts
  data/                 ports, ships, items, sailors and quest dialog
  world/, port/         movement, collision, wind and currents, NPCs
  state/                game state, selectors and actions
  quest/                which conversation plays in which building
  ui/                   interface: HUD, building screens and widgets
assets/
  images/               map tilesets and character spritesheets
  ui/                   interface images (sliced from ui/source)
  sound/                music
  data/                 world and port tilemaps, winds and currents
  fonts/                Inter
tests/                  unit tests, run outside of Defold
tools/                  scripts generating images and Defold resources
```

## Architecture

The game is made up of two parts:

- The **game** itself: `main/game.script` updates the port or the world map
  and renders it. The visible part of the map is copied into a Defold
  tilemap (one tile larger than the camera, so it can scroll smoothly), and
  characters are sprites created from factories.
- The **interface**: `main/hud.gui_script` redraws the GUI whenever
  something changes, using the small immediate-mode layer in
  `modules/ui/ui.lua`. It takes the place of React in the browser version:
  render functions describe the screen, click regions and key handlers are
  registered while drawing, and widget state (the highlighted menu option,
  a number being typed) is kept between redraws.

Both share the same Lua state (`[script] shared_state = 1`). During gameplay,
**actions** (`modules/state/actions_*.lua`) update **state**, and push
values the interface shows (date, gold, wind) through
`modules/state/ui_bridge.lua`.

The GUI script receives all input. Keys used for movement are passed on to
`modules/input_state.lua`, which the game loop reads.

#### Game loop

State changes, such as reading input and translating it to movement, don't
occur every frame — they happen every 67ms. Each frame does, however,
interpolate movement for smoother graphics.

#### Tests

The game logic doesn't depend on Defold, so it's tested with a plain Lua
interpreter. `tests/hud_test.lua` and `tests/game_script_test.lua` run the
interface and the game loop with stand-ins for Defold's APIs.

```sh
lua tests/run.lua
```

#### Regenerating resources

```sh
python3 tools/slice_ui_images.py       # after changing assets/ui/source
python3 tools/gen_defold_resources.py  # atlas, fonts, tilesources, tilemaps
```

#### Future considerations

- Players need the ability to save and resume: state needs to be serialized,
  e.g. with `sys.save()`.
- Pathfinding for NPC fleets.
