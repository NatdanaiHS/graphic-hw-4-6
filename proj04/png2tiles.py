from PIL import Image

TILE = 16
COLS, ROWS = 80, 30

def to_6bit(r, g, b):
    """สี 24-bit (8 bit ต่อสี) -> 6-bit RRGGBB (เอาแค่ 2 bit บนของแต่ละสี)"""
    return (r >> 6) << 4 | (g >> 6) << 2 | (b >> 6)

tiles = [(0x3F,) * (TILE * TILE)]
tile_id_of = {tiles[0]: 0}
game_map = []

for name in ["art/back.png", "art/front.png"]:
    img = Image.open(name).convert("RGB")
    for row in range(ROWS):
        line = []
        for col in range(COLS):

            tile = tuple(to_6bit(*img.getpixel((col * TILE + x, row * TILE + y)))
                         for y in range(TILE) for x in range(TILE))
            if tile not in tile_id_of:
                tile_id_of[tile] = len(tiles)
                tiles.append(tile)
            line.append(tile_id_of[tile])
        game_map.append(line)

assert len(tiles) <= 256, f"tile {len(tiles)} แบบ เกิน 256"
print("tiles used:", len(tiles), "/ 256")

with open("data/beach_map.mem", "w") as f:
    for line in game_map:
        f.write(" ".join(f"{t:02x}" for t in line) + "\n")

sheet = [[0x3F] * 256 for _ in range(256)]
for n, tile in enumerate(tiles):
    for y in range(TILE):
        for x in range(TILE):
            sheet[n // 16 * TILE + y][n % 16 * TILE + x] = tile[y * TILE + x]

with open("data/beach_tiles.mem", "w") as f:
    for line in sheet:
        for v in line:
            f.write(f"{v:02x}\n")

out = Image.new("RGB", (256, 256))
out.putdata([((v >> 4 & 3) * 85, (v >> 2 & 3) * 85, (v & 3) * 85) for line in sheet for v in line])
out.save("data/beach_tiles.png")
