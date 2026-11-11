`default_nettype none

// =====================================================================
// HW4 : Scrolling Background - ชายหาด (Tile + Map + Parallax Scroll)
// ---------------------------------------------------------------------
// ไอเดีย:  แทนที่จะเก็บรูปเต็มจอ (640x480 = เปลือง memory มาก)
//          เราเก็บ "ชิ้นส่วน" 16x16 (tile) + "แผนที่" ว่าช่องไหนใช้ชิ้นไหน
//
// Parallax = ของที่อยู่ไกลเลื่อนช้า ของที่อยู่ใกล้เลื่อนเร็ว -> ดูมีความลึก
//   มี 3 ความเร็ว:  เมฆ 1 px/เฟรม   ทะเล 2 px/เฟรม   ชายหาด 4 px/เฟรม
//
// มี 2 ชั้นซ้อนกัน (แบบ BG layer ของ SNES):
//   ชั้นหน้า  (ต้นมะพร้าว ทราย)   ถ้า pixel เป็นสีขาว 3F = โปร่งใส ->
//   ชั้นหลัง  (ฟ้า เมฆ ทะเล)
// รูปทั้ง 2 ชั้นมาจาก art/back.png, art/front.png แปลงด้วย png2tiles.py
//
//   pix_x + scroll ---> world_x ---> MAP ROM ---> tile_id ---> TILE ROM ---> สี
//
// ปุ่ม:  ui_in[0] = เลื่อนซ้าย   ui_in[1] = เลื่อนขวา   ui_in[2] = เลื่อนเองอัตโนมัติ
// =====================================================================
module tt_um_vga_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  // ---------------- VGA (เหมือนทุกงาน) ----------------
  wire hsync, vsync, video_active;
  wire [9:0] pix_x, pix_y;
  reg  [5:0] color;                       // สีสุดท้าย RRGGBB

  assign uo_out  = {hsync, color[0], color[2], color[4], vsync, color[1], color[3], color[5]};
  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused_ok = &{ena, ui_in[7:3], uio_in};

  hvsync_generator vga_sync_gen (
      .clk(clk), .reset(~rst_n),
      .hsync(hsync), .vsync(vsync), .display_on(video_active),
      .hpos(pix_x), .vpos(pix_y)
  );

  localparam MAP_W       = 1280;          // ความกว้างแผนที่ (80 tiles x 16 px)
  localparam TRANSPARENT = 6'h3F;         // สีขาวล้วนใน tile = โปร่งใส

  // บวกแล้ววนในแผนที่: ผลลัพธ์อยู่ในช่วง 0..1279 เสมอ (wrap around)
  //   เลื่อนซ้าย 1 = บวก 1279 (วนรอบ 1280 แล้วถอยมา 1 ช่องพอดี)
  function [10:0] wrap_add(input [10:0] a, input [10:0] b);
    wrap_add = (a + b >= MAP_W) ? (a + b - MAP_W) : (a + b);
  endfunction

  // ---------------- 1) scroll ของแต่ละชั้น ----------------
  reg [10:0] scroll_cloud;                // เมฆ    (ไกลสุด ช้าสุด)
  reg [10:0] scroll_sea;                  // ทะเล
  reg [10:0] scroll_beach;                // ชายหาด (ใกล้สุด เร็วสุด)

  wire go_left  = ui_in[0];
  wire go_right = ui_in[1] | ui_in[2];

  // new_frame = 1 แค่ 1 clock ต่อเฟรม (ตอนวาดจอเสร็จ) -> อัปเดต 60 ครั้งต่อวินาที
  wire new_frame = (pix_x == 0) && (pix_y == 480);

  always @(posedge clk) begin
    if (!rst_n) begin
      scroll_cloud <= 0;
      scroll_sea   <= 0;
      scroll_beach <= 0;
    end else if (new_frame && (go_left || go_right)) begin
      scroll_cloud <= wrap_add(scroll_cloud, go_left ? MAP_W - 1 : 1);
      scroll_sea   <= wrap_add(scroll_sea,   go_left ? MAP_W - 2 : 2);
      scroll_beach <= wrap_add(scroll_beach, go_left ? MAP_W - 4 : 4);
    end
  end

  // ---------------- 2) ตำแหน่งในแผนที่ (world_x) ของแต่ละชั้น ----------------
  // ชั้นหลัง: ส่วนฟ้า (y < 192) ใช้ scroll ของเมฆ, ส่วนล่างใช้ scroll ของทะเล
  //           (เปลี่ยนค่า scroll ตามบรรทัด แบบที่ SNES ทำ)
  wire [10:0] back_x  = wrap_add(pix_x, (pix_y < 192) ? scroll_cloud : scroll_sea);
  wire [10:0] front_x = wrap_add(pix_x, scroll_beach);

  // ---------------- 3) ชั้นหลัง : MAP ROM -> TILE ROM ----------------
  wire [7:0] back_tile;
  wire [5:0] back_color;
  map_rom  map_back   (.layer(1'b0), .col(back_x[10:4]), .row(pix_y[8:4]), .tile_id(back_tile));
  tile_rom tiles_back (.tile_id(back_tile), .px(back_x[3:0]), .py(pix_y[3:0]), .color(back_color));

  // ---------------- 4) ชั้นหน้า : MAP ROM -> TILE ROM ----------------
  wire [7:0] front_tile;
  wire [5:0] front_color;
  map_rom  map_front   (.layer(1'b1), .col(front_x[10:4]), .row(pix_y[8:4]), .tile_id(front_tile));
  tile_rom tiles_front (.tile_id(front_tile), .px(front_x[3:0]), .py(pix_y[3:0]), .color(front_color));

  // ---------------- 5) รวมชั้น แล้วส่งสีออกจอ ----------------
  always @(posedge clk) begin
    if (!video_active)                   color <= 0;            // นอกจอต้องเป็นดำ
    else if (front_color != TRANSPARENT) color <= front_color;  // ชั้นหน้าบังชั้นหลัง
    else                                 color <= back_color;   // โปร่งใส -> เห็นชั้นหลัง
  end

endmodule
