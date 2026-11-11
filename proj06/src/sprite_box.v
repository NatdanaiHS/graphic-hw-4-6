`default_nettype none

// =====================================================================
// SPRITE BOX : เช็คว่า pixel ที่จอกำลังวาด "อยู่ในกรอบ sprite" ไหม
// ---------------------------------------------------------------------
//   (pos_x, pos_y) = มุมซ้ายบนของ sprite (พิกัดในแผนที่/world)
//   SIZE           = ขนาด sprite บนจอ (16 หรือ 32)
//
//         pos_x            pos_x+SIZE
//   pos_y   +-----------------+
//           |   dx -->        |      hit = 1 ถ้าอยู่ในกรอบนี้
//           |   dy            |      dx, dy = ตำแหน่งภายในกรอบ
//           |   v             |               (ใช้ไปหยิบสีจาก ROM)
//           +-----------------+
//
//   flip = 1 -> กลับซ้ายขวา (dx = SIZE-1-dx) ใช้ให้ตัวละครหันอีกด้าน
// =====================================================================
module sprite_box #(
    parameter SIZE = 16
) (
    input  wire [10:0] world_x,   // x ที่กำลังวาด (บวก scroll แล้ว)
    input  wire [9:0]  y,         // y ที่กำลังวาด
    input  wire [10:0] pos_x,     // มุมซ้ายบนของ sprite
    input  wire [9:0]  pos_y,
    input  wire        flip,
    output wire        hit,
    output wire [4:0]  dx,        // 0..SIZE-1
    output wire [4:0]  dy
);
  assign hit = (world_x >= pos_x) && (world_x < pos_x + SIZE) &&
                  (y       >= pos_y) && (y       < pos_y + SIZE);

  wire [4:0] rel_x = world_x - pos_x;   // ระยะห่างจากขอบซ้าย
  wire [4:0] rel_y = y - pos_y;         // ระยะห่างจากขอบบน

  assign dx = flip ? (SIZE - 1 - rel_x) : rel_x;
  assign dy = rel_y;
endmodule
