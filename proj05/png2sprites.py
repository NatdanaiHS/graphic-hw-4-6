from PIL import Image

img = Image.open("art/sprites.png").convert("RGB")

with open("data/sprites.mem", "w") as f:
    for y in range(32):
        for x in range(256):
            r, g, b = img.getpixel((x, y))
            color = (r >> 6) << 4 | (g >> 6) << 2 | (b >> 6)
            f.write(f"{color:02x}\n")
