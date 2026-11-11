# HW5: Simple PPU – Beach Walk

A small Picture Processing Unit built on top of HW4: the two scrolling background
layers plus a sprite layer (a player, a crab and 3 beach balls, all my own pixel art).
It supports flip, animation, show/hide, a transparency key (`3F`), layer priority,
and a camera that follows the player with parallax.

![preview](preview.png)

## Controls
- `ui_in[0]`: walk left
- `ui_in[1]`: walk right

## Sprite sheet
`art/sprites.png` (8 cells of 32x32, white = transparent) → `python png2sprites.py` → `data/sprites.mem`

![sprites](art/sprites.png)

The background data (`beach_tiles.mem`, `beach_map.mem`) comes from HW4 ([../proj04](../proj04)).

## Files (read in this order)
`src/sprite.v` → `src/ppu.v` → `src/project.v` (`map_rom.v`, `tile_rom.v` are the same as HW4).

Explanation in Thai: [../GUIDE_HW4-6.md](../GUIDE_HW4-6.md)
