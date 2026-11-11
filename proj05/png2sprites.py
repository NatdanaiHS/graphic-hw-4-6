# =====================================================================
# png2sprites.py : แปลงรูป sprite sheet เป็น SPRITE ROM
# ---------------------------------------------------------------------
# รัน:  python png2sprites.py     (ต้องมี Pillow: pip install pillow)
#
# art/sprites.png  ขนาด 256x32 = 8 ช่อง ช่องละ 32x32   (สีขาวล้วน = โปร่งใส)
#   ช่อง 0 ยืน | 1,2 เดิน | 3 กระโดด | 4,5 ปู | 6,7 ลูกบอล
#
# data/sprites.mem = pixel ทุกจุด เรียงซ้ายไปขวา บนลงล่าง สี 6-bit RRGGBB
#
# (พื้นหลัง beach_tiles.mem, beach_map.mem ใช้ของ HW4 : proj04/png2tiles.py)
# =====================================================================
from PIL import Image

img = Image.open("art/sprites.png").convert("RGB")

with open("data/sprites.mem", "w") as f:
    for y in range(32):
        for x in range(256):
            r, g, b = img.getpixel((x, y))
            color = (r >> 6) << 4 | (g >> 6) << 2 | (b >> 6)   # 24-bit -> 6-bit
            f.write(f"{color:02x}\n")
