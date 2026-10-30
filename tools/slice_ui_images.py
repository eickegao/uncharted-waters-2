"""
Slices the interface spritesheets in assets/ui/source into the individual
images referenced by assets/ui/ui.atlas.

Run from the repository root after changing anything in assets/ui/source:
    python3 tools/slice_ui_images.py
"""

import os
from PIL import Image

SOURCE = "assets/ui/source"
OUT = "assets/ui"

# name, slice width, output prefix, first id
SHEETS = [
    ("buildings", 136, "building_", 1),
    ("items", 48, "item_", 0),
    ("characters", 64, "character_", 1),
    ("ships", 128, "ship_", 1),
    ("world_indicators", 80, "indicator_", 0),
]

SINGLES = [
    "dialog_corner",
    "dialog_caret_down",
    "dialog_ship",
    "dialog_yes",
    "dialog_no",
    "dialog_submit",
    "world_water",
    "world_food",
    "world_lumber",
    "world_shot",
]

# number arrived at through visual inspection
FLEET_TILESET_ROW = 27


def tile(image, columns, rows):
    result = Image.new(image.mode, (image.width * columns, image.height * rows))
    if image.mode == "P":
        result.putpalette(image.getpalette())
    for y in range(rows):
        for x in range(columns):
            result.paste(image, (x * image.width, y * image.height))
    return result


def main():
    for name, width, prefix, first_id in SHEETS:
        sheet = Image.open(os.path.join(SOURCE, name + ".png"))
        for i in range(sheet.width // width):
            part = sheet.crop((i * width, 0, (i + 1) * width, sheet.height))
            part.save(os.path.join(OUT, "%s%d.png" % (prefix, i + first_id)))

    for name in SINGLES:
        Image.open(os.path.join(SOURCE, name + ".png")).save(os.path.join(OUT, name + ".png"))

    # the building background is shown at 2x, covering the 1280x800 camera
    background = Image.open(os.path.join(SOURCE, "building_background.png"))
    tile(background, 5, 7).save(os.path.join(OUT, "building_background.png"))

    # Fleet popover background: a single ocean tile from the world tileset
    tileset = Image.open("assets/images/world_tileset.png").convert("RGB")
    ocean = tileset.crop((0, FLEET_TILESET_ROW * 16, 16, (FLEET_TILESET_ROW + 1) * 16))
    tile(ocean, 40, 19).save(os.path.join(OUT, "fleet_background.png"))


if __name__ == "__main__":
    main()
