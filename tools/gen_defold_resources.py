"""
Generates Defold resource files that are tedious to write by hand:

  - assets/ui/ui.atlas: every image in assets/ui (see slice_ui_images.py)
  - assets/fonts/*.font: Inter in the sizes used by the interface, including
    the non-ASCII characters found in modules/
  - assets/images/*.tilesource: tilesets for the maps and spritesheets for
    characters, with one animation per frame
  - main/world.tilemap and main/port.tilemap: tilemaps with cells covering the
    camera, filled in at runtime by main/game.script

Run from the repository root:
    python3 tools/gen_defold_resources.py
"""

import glob
import os

# name: (font file, size)
FONTS = {
    "r14": ("Inter-Regular.otf", 14),
    "r16": ("Inter-Regular.otf", 16),
    "r18": ("Inter-Regular.otf", 18),
    "r20": ("Inter-Regular.otf", 20),
    "r24": ("Inter-Regular.otf", 24),
    "r36": ("Inter-Regular.otf", 36),
    "b18": ("Inter-Bold.otf", 18),
    "b24": ("Inter-Bold.otf", 24),
    "b36": ("Inter-Bold.otf", 36),
}

# name: (image, tile width, tile height, frame animations)
TILESOURCES = {
    "world_tileset": ("world_tileset.png", 16, 16, 0),
    "port_tilesets": ("port_tilesets.png", 16, 16, 0),
    "world_ships": ("world_ships.png", 32, 32, 32),
    "port_characters": ("port_characters.png", 32, 32, 32),
}

# id: tilesource
TILEMAPS = {
    "world": "world_tileset",
    "port": "port_tilesets",
}
TILEMAP_COLUMNS = 41
TILEMAP_ROWS = 26


def escape(text):
    """Protobuf text format string, with UTF-8 bytes as octal escapes"""
    result = []
    for byte in text.encode("utf-8"):
        char = chr(byte)
        if char in "\\\"":
            result.append("\\" + char)
        elif 32 <= byte < 127:
            result.append(char)
        else:
            result.append("\\%03o" % byte)
    return '"' + "".join(result) + '"'


def write(path, content):
    with open(path, "w") as f:
        f.write(content)


def atlas():
    images = sorted(glob.glob("assets/ui/*.png"))
    content = ""
    for image in images:
        content += 'images {\n  image: "/%s"\n  sprite_trim_mode: SPRITE_TRIM_MODE_OFF\n}\n' % image
    content += "margin: 0\nextrude_borders: 2\ninner_padding: 0\nmax_page_width: 0\nmax_page_height: 0\n"
    write("assets/ui/ui.atlas", content)


def extra_characters():
    characters = set("☆")
    for path in glob.glob("modules/**/*.lua", recursive=True):
        with open(path, encoding="utf-8") as f:
            characters.update(c for c in f.read() if ord(c) > 126)
    return "".join(sorted(characters))


def fonts():
    extra = extra_characters()
    for name, (font, size) in FONTS.items():
        write(
            "assets/fonts/%s.font" % name,
            'font: "/assets/fonts/%s"\n'
            'material: "/builtins/fonts/font.material"\n'
            "size: %d\n"
            "antialias: 1\n"
            "alpha: 1.0\n"
            "outline_alpha: 0.0\n"
            "outline_width: 0.0\n"
            "shadow_alpha: 0.0\n"
            "shadow_blur: 0\n"
            "shadow_x: 0.0\n"
            "shadow_y: 0.0\n"
            "extra_characters: %s\n"
            "output_format: TYPE_BITMAP\n"
            "all_chars: false\n"
            "cache_width: 0\n"
            "cache_height: 0\n"
            "render_mode: MODE_SINGLE_LAYER\n" % (font, size, escape(extra)),
        )


def tilesources():
    for name, (image, width, height, frames) in TILESOURCES.items():
        content = (
            'image: "/assets/images/%s"\n'
            "tile_width: %d\n"
            "tile_height: %d\n"
            "tile_margin: 0\n"
            "tile_spacing: 0\n"
            'collision: ""\n'
            'material_tag: "tile"\n'
            'collision_groups: "default"\n'
            "extrude_borders: 0\n"
            "inner_padding: 0\n"
            "sprite_trim_mode: SPRITE_TRIM_MODE_OFF\n" % (image, width, height)
        )
        for frame in range(frames):
            content += (
                "animations {\n"
                '  id: "f%d"\n'
                "  start_tile: %d\n"
                "  end_tile: %d\n"
                "  playback: PLAYBACK_NONE\n"
                "  fps: 30\n"
                "  flip_horizontal: 0\n"
                "  flip_vertical: 0\n"
                "}\n" % (frame, frame + 1, frame + 1)
            )
        write("assets/images/%s.tilesource" % name, content)


def tilemaps():
    for name, tilesource in TILEMAPS.items():
        cells = "".join(
            "  cell {\n    x: %d\n    y: %d\n    tile: 0\n    h_flip: 0\n    v_flip: 0\n  }\n" % (x, y)
            for y in range(TILEMAP_ROWS)
            for x in range(TILEMAP_COLUMNS)
        )
        write(
            "main/%s.tilemap" % name,
            'tile_set: "/assets/images/%s.tilesource"\n'
            "layers {\n"
            '  id: "layer1"\n'
            "  z: 0.0\n"
            "  is_visible: 1\n"
            "%s"
            "}\n"
            'material: "/builtins/materials/tile_map.material"\n'
            "blend_mode: BLEND_MODE_ALPHA\n" % (tilesource, cells),
        )


if __name__ == "__main__":
    atlas()
    fonts()
    tilesources()
    tilemaps()
