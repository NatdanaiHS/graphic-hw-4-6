# =====================================================================
# png2tiles.py : แปลงรูป PNG เป็น TILE ROM + MAP ROM
# ---------------------------------------------------------------------
# รัน:  python png2tiles.py     (ต้องมี Pillow: pip install pillow)
#
# รูปต้นทาง (1280x480 px = 80x30 ช่อง ช่องละ 16x16):
#   art/back.png   ชั้นหลัง : ฟ้า เมฆ ทะเล
#   art/front.png  ชั้นหน้า : ต้นมะพร้าว ชายหาด   (สีขาวล้วน = โปร่งใส)
#
# ไฟล์ที่ได้:
#   data/beach_tiles.mem  รูป tile sheet 256x256 (tile ได้สูงสุด 256 แบบ) สี 6-bit
#   data/beach_map.mem    แผนที่ 80x60 ช่อง (แถว 0-29 = back, แถว 30-59 = front)
#
# หลักการ: หั่นรูปเป็นช่อง 16x16  ช่องไหนหน้าตา "ซ้ำ" กับที่เคยเจอ ใช้ tile เดิม
#          ช่องไหนเป็นแบบใหม่ ค่อยเพิ่ม tile ใหม่   แผนที่จำแค่ "เลข tile" ของแต่ละช่อง
#          (ทะเล ทราย ฟ้า ซ้ำกันเยอะ -> ทั้งฉากใช้ tile ไม่กี่สิบแบบ)
# =====================================================================
from PIL import Image

TILE = 16                 # tile 16x16 px
COLS, ROWS = 80, 30       # แผนที่ 80x30 ช่อง

def to_6bit(r, g, b):
    """สี 24-bit (8 bit ต่อสี) -> 6-bit RRGGBB (เอาแค่ 2 bit บนของแต่ละสี)"""
    return (r >> 6) << 4 | (g >> 6) << 2 | (b >> 6)

tiles = [(0x3F,) * (TILE * TILE)]   # tile 0 = ขาวล้วน (3F) = โปร่งใส
tile_id_of = {tiles[0]: 0}          # หน้าตา tile -> เลข tile (ใช้เช็คว่าซ้ำไหม)
game_map = []                       # เลข tile ของทุกช่อง ทีละแถว

for name in ["art/back.png", "art/front.png"]:
    img = Image.open(name).convert("RGB")
    for row in range(ROWS):
        line = []
        for col in range(COLS):
            # อ่าน 256 pixel ของช่องนี้ (ซ้ายไปขวา บนลงล่าง)
            tile = tuple(to_6bit(*img.getpixel((col * TILE + x, row * TILE + y)))
                         for y in range(TILE) for x in range(TILE))
            if tile not in tile_id_of:          # แบบใหม่ -> เพิ่มเข้า tile sheet
                tile_id_of[tile] = len(tiles)
                tiles.append(tile)
            line.append(tile_id_of[tile])
        game_map.append(line)

assert len(tiles) <= 256, f"tile {len(tiles)} แบบ เกิน 256"
print("tiles used:", len(tiles), "/ 256")

# ---- MAP ROM : 1 บรรทัด = 1 แถวของแผนที่ ----
with open("data/beach_map.mem", "w") as f:
    for line in game_map:
        f.write(" ".join(f"{t:02x}" for t in line) + "\n")

# ---- TILE ROM : วาง tile ลงรูป sheet 256x256 (16x16 ช่อง) แล้วเขียนทีละ pixel ----
# tile เบอร์ n อยู่ที่แถว n/16 คอลัมน์ n%16  ตรงกับ tile_id[7:4], tile_id[3:0] ใน tile_rom.v
sheet = [[0x3F] * 256 for _ in range(256)]
for n, tile in enumerate(tiles):
    for y in range(TILE):
        for x in range(TILE):
            sheet[n // 16 * TILE + y][n % 16 * TILE + x] = tile[y * TILE + x]

with open("data/beach_tiles.mem", "w") as f:
    for line in sheet:
        for v in line:
            f.write(f"{v:02x}\n")

# รูป tile sheet ไว้ดูเฉยๆ (Verilog ไม่ได้ใช้)
out = Image.new("RGB", (256, 256))
out.putdata([((v >> 4 & 3) * 85, (v >> 2 & 3) * 85, (v & 3) * 85) for line in sheet for v in line])
out.save("data/beach_tiles.png")
