`default_nettype none

// =====================================================================
// TILE ROM  (= "Pattern Table" ใน NES)
// ---------------------------------------------------------------------
// เก็บ "หน้าตา" ของ tile ทั้ง 256 แบบ
//   ไฟล์ beach_tiles.mem (สร้างจากรูป PNG ด้วย png2tiles.py) เป็นรูป 256x256 px  (6-bit สี RRGGBB)
//   แบ่งเป็นตาราง 16x16 ช่อง  ช่องละ 16x16 px  -> 256 tiles
//
//   tile_id 8 bit = [7:4] แถวในรูป , [3:0] คอลัมน์ในรูป
//
//   ตำแหน่ง pixel ในรูปใหญ่:
//       y_in_sheet = tile_id[7:4]*16 + py
//       x_in_sheet = tile_id[3:0]*16 + px
//       index      = y_in_sheet * 256 + x_in_sheet
//   เพราะทุกตัวเป็นเลขยกกำลัง 2  เลยเขียนเป็นการต่อ bit ได้เลย:
//       index = { tile_id[7:4], py, tile_id[3:0], px }   (4+4+4+4 = 16 bit)
// =====================================================================
module tile_rom (
    input  wire [7:0] tile_id,  // tile เบอร์อะไร (จาก map_rom)
    input  wire [3:0] px,       // pixel ที่เท่าไรใน tile (แนวนอน 0..15)
    input  wire [3:0] py,       // pixel ที่เท่าไรใน tile (แนวตั้ง 0..15)
    output wire [5:0] color     // สี RRGGBB
);
  reg [5:0] mem [0:256*256-1];  // 65536 pixel

  initial $readmemh("../data/beach_tiles.mem", mem);

  assign color = mem[{tile_id[7:4], py, tile_id[3:0], px}];
endmodule
