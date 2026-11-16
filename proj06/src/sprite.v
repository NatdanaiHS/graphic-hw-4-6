`default_nettype none

// =====================================================================
// SPRITE : วาด sprite 32x32 หนึ่งตัว
// ---------------------------------------------------------------------
// ตอบคำถาม "pixel ที่กำลังวาด (world_x, y) เป็นสีอะไรของ sprite ตัวนี้"
//
//         pos_x            pos_x+32
//   pos_y   +-----------------+
//           |   dx -->        |    1) อยู่ในกรอบไหม            (เหมือนลูกบอลใน Pong)
//           |   dy            |    2) ถ้าอยู่: dx, dy = ตำแหน่งในกรอบ -> ไปหยิบสีจาก ROM
//           |   v             |    3) ถ้าไม่อยู่: ตอบ 3F (โปร่งใส)
//           +-----------------+
//
// SPRITE ROM = รูป sprite sheet 256x32 (8 ช่อง ช่องละ 32x32) จาก art/sprites.png
//   frame  = เลือกช่องในรูป (ท่าทาง)     0 ยืน | 1,2 เดิน | 3 กระโดด | 4,5 ปู | 6,7 ลูกบอล
//   index = dy*256 + frame*32 + dx  =  {dy, frame, dx}   (5+3+5 = 13 bit)
// =====================================================================
module sprite (
    input  wire [10:0] world_x,   // x ที่กำลังวาด (บวก scroll แล้ว)
    input  wire [9:0]  y,         // y ที่กำลังวาด
    input  wire [10:0] pos_x,     // มุมซ้ายบนของ sprite (พิกัดในแผนที่)
    input  wire [9:0]  pos_y,
    input  wire [2:0]  frame,     // ใช้รูปช่องไหน
    input  wire        flip,      // 1 = กลับซ้ายขวา
    input  wire        show,      // 0 = ซ่อน
    output wire [5:0]  color      // 3F = โปร่งใส
);
  reg [5:0] mem [0:256*32-1];
  initial $readmemh("../data/sprites.mem", mem);

  wire [10:0] off_x = world_x - pos_x;      // ระยะจากขอบซ้ายของ sprite
  wire [9:0]  off_y = y - pos_y;            // ระยะจากขอบบน

  // ถ้า pixel อยู่ซ้าย/บนของ sprite ผลลบจะวนเป็นเลขใหญ่มาก จึงเช็คแค่ < 32 ก็พอ
  wire hit = show && (off_x < 32) && (off_y < 32);

  wire [4:0] dx = flip ? ~off_x[4:0] : off_x[4:0];   // ~dx = 31 - dx = อ่านรูปจากขวามาซ้าย
  wire [4:0] dy = off_y[4:0];

  assign color = hit ? mem[{dy, frame, dx}] : 6'h3F;
endmodule
