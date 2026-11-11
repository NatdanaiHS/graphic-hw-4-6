`default_nettype none

// =====================================================================
// PPU (Picture Processing Unit) แบบง่าย
// ---------------------------------------------------------------------
// หน้าที่ของ PPU: "รับข้อมูลว่าอะไรอยู่ตรงไหน แล้ววาดออกจอ"
//                 ตัว PPU ไม่รู้กติกาเกมเลย  (กติกาอยู่ใน project.v)
//
// PPU นี้มี 2 ชั้น (layer):
//   1) Background layer : map_rom + tile_rom  (เหมือน HW4)
//   2) Sprite layer     : Mario 1 ตัว, Goomba 1 ตัว, เหรียญ 3 เหรียญ
//
// ข้อมูลของ sprite (x, y, ท่า, หันซ้าย/ขวา, แสดงไหม) ส่งเข้ามาทาง port
//   -> นี่คือ OAM (Object Attribute Memory) ใน NES  แค่เราเก็บเป็น reg ใน top
//
// การรวมชั้น (priority):  Mario > Goomba > Coin > Background
//   sprite ไหนสีเป็น 3F (ขาว) = โปร่งใส  -> มองทะลุไปชั้นถัดไป
// =====================================================================
module ppu (
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    input  wire [10:0] scroll_x,      // กล้องอยู่ตรงไหนของแผนที่ (0..640)

    // ----- OAM : Mario -----
    input  wire [10:0] mario_x,
    input  wire [9:0]  mario_y,
    input  wire [1:0]  mario_frame,   // 0 ยืน 1,2 เดิน 3 กระโดด
    input  wire        mario_right,   // 1 = หันขวา

    // ----- OAM : Goomba -----
    input  wire [10:0] goomba_x,
    input  wire [9:0]  goomba_y,
    input  wire        goomba_frame,
    input  wire        goomba_show,

    // ----- OAM : Coins (3 เหรียญ ใช้ท่าเดียวกัน) -----
    input  wire [1:0]  coin_frame,
    input  wire [10:0] coin0_x, coin1_x, coin2_x,
    input  wire [9:0]  coin_y,
    input  wire [2:0]  coin_show,     // bit ละเหรียญ

    output wire [5:0]  color
);
  localparam SKY   = 6'b10_11_11;
  localparam CLEAR = 6'h3F;           // สีโปร่งใส

  wire [10:0] world_x = pix_x + scroll_x;

  // ================= Layer 1 : Background =================
  wire [7:0] tile_id;
  wire [5:0] tile_color;
  map_rom  map   (.col(world_x[10:4]), .row(pix_y[8:4]), .tile_id(tile_id));
  tile_rom tiles (.tile_id(tile_id), .px(world_x[3:0]), .py(pix_y[3:0]), .color(tile_color));

  wire [5:0] bg_color = (tile_id == 0 || tile_color == CLEAR) ? SKY : tile_color;

  // ================= Layer 2 : Sprites =================
  // ---- Mario (32x32) ----
  wire       m_in;  wire [4:0] m_dx, m_dy;  wire [5:0] m_rom;
  sprite_box #(.SIZE(32)) m_box (.world_x(world_x), .y(pix_y), .pos_x(mario_x), .pos_y(mario_y),
                                 .flip(mario_right), .hit(m_in), .dx(m_dx), .dy(m_dy));
  mario_rom m_img (.frame(mario_frame), .dx(m_dx), .dy(m_dy), .color(m_rom));
  wire [5:0] mario_color = m_in ? m_rom : CLEAR;

  // ---- Goomba (รูป 16x16 แต่วาดขยาย 2 เท่าเป็น 32x32 : ใช้ dx/2, dy/2) ----
  wire       g_in;  wire [4:0] g_dx, g_dy;  wire [5:0] g_rom;
  sprite_box #(.SIZE(32)) g_box (.world_x(world_x), .y(pix_y), .pos_x(goomba_x), .pos_y(goomba_y),
                                 .flip(1'b0), .hit(g_in), .dx(g_dx), .dy(g_dy));
  goomba_rom g_img (.frame(goomba_frame), .dx(g_dx[4:1]), .dy(g_dy[4:1]), .color(g_rom));
  wire [5:0] goomba_color = (g_in && goomba_show) ? g_rom : CLEAR;

  // ---- Coins (16x16) x 3 : ใช้ ROM ร่วมกันไม่ได้เพราะอ่านพร้อมกัน จึงมี 3 ชุด ----
  wire       c0_in, c1_in, c2_in;
  wire [4:0] c0_dx, c0_dy, c1_dx, c1_dy, c2_dx, c2_dy;
  wire [5:0] c0_rom, c1_rom, c2_rom;
  sprite_box #(.SIZE(16)) c0_box (.world_x(world_x), .y(pix_y), .pos_x(coin0_x), .pos_y(coin_y),
                                  .flip(1'b0), .hit(c0_in), .dx(c0_dx), .dy(c0_dy));
  sprite_box #(.SIZE(16)) c1_box (.world_x(world_x), .y(pix_y), .pos_x(coin1_x), .pos_y(coin_y),
                                  .flip(1'b0), .hit(c1_in), .dx(c1_dx), .dy(c1_dy));
  sprite_box #(.SIZE(16)) c2_box (.world_x(world_x), .y(pix_y), .pos_x(coin2_x), .pos_y(coin_y),
                                  .flip(1'b0), .hit(c2_in), .dx(c2_dx), .dy(c2_dy));
  coin_rom c0_img (.frame(coin_frame), .dx(c0_dx[3:0]), .dy(c0_dy[3:0]), .color(c0_rom));
  coin_rom c1_img (.frame(coin_frame), .dx(c1_dx[3:0]), .dy(c1_dy[3:0]), .color(c1_rom));
  coin_rom c2_img (.frame(coin_frame), .dx(c2_dx[3:0]), .dy(c2_dy[3:0]), .color(c2_rom));

  wire [5:0] coin_color = (c0_in && coin_show[0]) ? c0_rom :
                          (c1_in && coin_show[1]) ? c1_rom :
                          (c2_in && coin_show[2]) ? c2_rom : CLEAR;

  // ================= Mixer : เลือกชั้นที่อยู่บนสุดที่ไม่โปร่งใส =================
  assign color = (mario_color  != CLEAR) ? mario_color  :
                 (goomba_color != CLEAR) ? goomba_color :
                 (coin_color   != CLEAR) ? coin_color   :
                                           bg_color;
endmodule
