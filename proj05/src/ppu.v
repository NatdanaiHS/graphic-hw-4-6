`default_nettype none

// =====================================================================
// PPU (Picture Processing Unit) แบบง่าย
// ---------------------------------------------------------------------
// หน้าที่ของ PPU: "รับข้อมูลว่าอะไรอยู่ตรงไหน แล้วตอบว่า pixel นี้สีอะไร"
//                 PPU ไม่รู้กติกาเกมเลย  (กติกาอยู่ใน project.v)
//
// มี 3 ชั้น เรียงจากหน้าไปหลัง:
//   1) Sprite     : คน 1, ปู 1, ลูกบอล 3      (sprite.v x 5)
//   2) BG หน้า    : ต้นมะพร้าว ชายหาด          (เหมือน HW4)
//   3) BG หลัง    : ฟ้า เมฆ ทะเล               (เหมือน HW4)
//   ชั้นไหนสีเป็น 3F (ขาว) = โปร่งใส -> มองทะลุไปชั้นถัดไป
//
// ข้อมูลของ sprite (x, y, ท่า, กลับด้าน, แสดงไหม) รับเข้ามาทาง port
//   = OAM (Object Attribute Memory) ของ NES
//
// scroll_x = ตำแหน่งกล้อง (0..640)   parallax ได้จากการ "หาร" ค่าเดียวกัน:
//   ชายหาด + sprite ใช้ scroll_x       ทะเลใช้ scroll_x/2      ฟ้าใช้ scroll_x/4
// =====================================================================
module ppu (
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    input  wire [10:0] scroll_x,      // กล้องอยู่ตรงไหนของแผนที่ (0..640)

    // ----- OAM : คน -----
    input  wire [10:0] player_x,
    input  wire [9:0]  player_y,
    input  wire [2:0]  player_frame,   // 0 ยืน | 1,2 เดิน | 3 กระโดด
    input  wire        player_flip,   // 1 = หันซ้าย

    // ----- OAM : ปู -----
    input  wire [10:0] crab_x,
    input  wire [9:0]  crab_y,
    input  wire [2:0]  crab_frame,     // 4, 5
    input  wire        crab_show,

    // ----- OAM : ลูกบอล 3 ลูก (ใช้ท่าและ y เดียวกัน) -----
    input  wire [10:0] ball0_x, ball1_x, ball2_x,
    input  wire [9:0]  ball_y,
    input  wire [2:0]  ball_frame,     // 6, 7
    input  wire [2:0]  ball_show,     // bit ละลูก

    output wire [5:0]  color
);
  localparam CLEAR = 6'h3F;           // สีโปร่งใส

  // ================= Background 2 ชั้น (HW4) =================
  // กล้องไปได้แค่ 0..640 -> pix_x + scroll ไม่เกิน 1279 จึงไม่ต้อง wrap
  wire [10:0] front_x = {1'b0, pix_x} + scroll_x;
  wire [10:0] back_x  = {1'b0, pix_x} + ((pix_y < 192) ? (scroll_x >> 2) : (scroll_x >> 1));

  wire [7:0] back_tile, front_tile;
  wire [5:0] back_color, front_color;
  map_rom  map_back    (.layer(1'b0), .col(back_x[10:4]),  .row(pix_y[8:4]), .tile_id(back_tile));
  tile_rom tiles_back  (.tile_id(back_tile),  .px(back_x[3:0]),  .py(pix_y[3:0]), .color(back_color));
  map_rom  map_front   (.layer(1'b1), .col(front_x[10:4]), .row(pix_y[8:4]), .tile_id(front_tile));
  tile_rom tiles_front (.tile_id(front_tile), .px(front_x[3:0]), .py(pix_y[3:0]), .color(front_color));

  // ================= Sprites =================
  // sprite อยู่บนชายหาด จึงใช้ world x เดียวกับ BG หน้า (front_x)
  wire [5:0] player_color, crab_color, ball0_color, ball1_color, ball2_color;

  sprite player (.world_x(front_x), .y(pix_y), .pos_x(player_x), .pos_y(player_y),
                 .frame(player_frame), .flip(player_flip), .show(1'b1), .color(player_color));

  sprite crab   (.world_x(front_x), .y(pix_y), .pos_x(crab_x), .pos_y(crab_y),
                 .frame(crab_frame), .flip(1'b0), .show(crab_show), .color(crab_color));

  sprite ball0  (.world_x(front_x), .y(pix_y), .pos_x(ball0_x), .pos_y(ball_y),
                 .frame(ball_frame), .flip(1'b0), .show(ball_show[0]), .color(ball0_color));
  sprite ball1  (.world_x(front_x), .y(pix_y), .pos_x(ball1_x), .pos_y(ball_y),
                 .frame(ball_frame), .flip(1'b0), .show(ball_show[1]), .color(ball1_color));
  sprite ball2  (.world_x(front_x), .y(pix_y), .pos_x(ball2_x), .pos_y(ball_y),
                 .frame(ball_frame), .flip(1'b0), .show(ball_show[2]), .color(ball2_color));

  // ================= Mixer : เลือกชั้นบนสุดที่ไม่โปร่งใส =================
  // priority:  คน > ปู > ลูกบอล > BG หน้า > BG หลัง
  assign color = (player_color != CLEAR) ? player_color :
                 (crab_color   != CLEAR) ? crab_color   :
                 (ball0_color  != CLEAR) ? ball0_color  :
                 (ball1_color  != CLEAR) ? ball1_color  :
                 (ball2_color  != CLEAR) ? ball2_color  :
                 (front_color  != CLEAR) ? front_color  :
                                           back_color;
endmodule
