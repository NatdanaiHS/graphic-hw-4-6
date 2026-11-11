`default_nettype none

// =====================================================================
// HW4 : Scrolling Background (Tile + Map + Scroll)
// ---------------------------------------------------------------------
// ไอเดีย:  แทนที่จะเก็บรูปเต็มจอ (640x480 = เปลือง memory มาก)
//          เราเก็บ "ชิ้นส่วน" 16x16 (tile) + "แผนที่" ว่าช่องไหนใช้ชิ้นไหน
//
//   pix_x, pix_y (จาก VGA)
//        |
//        +  scroll_x           <- เลื่อนกล้อง = บวก offset ให้ x
//        v
//   world_x, pix_y  (ตำแหน่งในแผนที่ใหญ่ 1280x480)
//        |
//        |-- [10:4] , [8:4] --> MAP ROM  --> tile_id    (ช่องนี้ใช้ tile อะไร)
//        |-- [3:0]  , [3:0] ----------------+
//                                           v
//                                       TILE ROM --> color (pixel นี้สีอะไร)
//
// ปุ่ม:  ui_in[0] = เลื่อนซ้าย   ui_in[1] = เลื่อนขวา   ui_in[2] = เลื่อนเองอัตโนมัติ
// พิเศษ: แถวบนสุด (เมฆ) เลื่อนช้ากว่าครึ่งหนึ่ง = parallax scrolling
//        เลื่อนจนสุดแผนที่แล้ววนกลับมาต้นแผนที่ (wrap around)
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

  // ---------------- 1) ตัวแปร scroll ----------------
  localparam MAP_WIDTH = 1280;            // ความกว้างแผนที่เป็น pixel (80 tiles x 16)
  localparam SKY_COLOR = 6'b10_11_11;     // ฟ้าอ่อน (ใช้กับ tile 0)

  reg [10:0] scroll_x;                    // กล้องอยู่ที่ x เท่าไรของแผนที่ (0..1279)

  // new_frame = 1 แค่ 1 clock ต่อเฟรม (ตอนวาดจอเสร็จ) -> ใช้อัปเดตเกม/ปุ่ม 60 ครั้งต่อวินาที
  wire new_frame = (pix_x == 0) && (pix_y == 480);

  always @(posedge clk) begin
    if (!rst_n) begin
      scroll_x <= 0;
    end else if (new_frame) begin
      if (ui_in[0]) begin                                  // ซ้าย
        if (scroll_x == 0) scroll_x <= MAP_WIDTH - 2;      // วนไปท้ายแผนที่
        else               scroll_x <= scroll_x - 2;
      end else if (ui_in[1] || ui_in[2]) begin             // ขวา / อัตโนมัติ
        if (scroll_x == MAP_WIDTH - 2) scroll_x <= 0;      // วนกลับต้นแผนที่
        else                           scroll_x <= scroll_x + 2;
      end
    end
  end

  // ---------------- 2) หาตำแหน่งในแผนที่ (world) ----------------
  // parallax: บริเวณเมฆ (y < 112) เลื่อนครึ่งความเร็ว ให้ดูเหมือนอยู่ไกลกว่า
  wire [10:0] line_scroll = (pix_y < 112) ? (scroll_x >> 1) : scroll_x;

  wire [11:0] sum_x   = pix_x + line_scroll;               // อาจเกิน 1280 ได้
  wire [10:0] world_x = (sum_x >= MAP_WIDTH) ? (sum_x - MAP_WIDTH) : sum_x[10:0];  // wrap

  // ---------------- 3) MAP ROM : ช่องนี้ใช้ tile อะไร ----------------
  wire [7:0] tile_id;
  map_rom map (
      .col(world_x[10:4]),        // หาร 16 = ตัด 4 bit ล่างทิ้ง
      .row(pix_y[8:4]),
      .tile_id(tile_id)
  );

  // ---------------- 4) TILE ROM : pixel นี้ใน tile สีอะไร ----------------
  wire [5:0] tile_color;
  tile_rom tiles (
      .tile_id(tile_id),
      .px(world_x[3:0]),          // เศษจากการหาร 16 = ตำแหน่งใน tile
      .py(pix_y[3:0]),
      .color(tile_color)
  );

  // ---------------- 5) ส่งสีออกจอ ----------------
  always @(posedge clk) begin
    if (!video_active)   color <= 0;          // นอกจอต้องเป็นดำ
    else if (tile_id == 0) color <= SKY_COLOR;     // ช่องว่าง = ฟ้า
    else if (tile_color == 6'h3F) color <= SKY_COLOR; // สีขาว 3F ใน tile = โปร่งใส -> เห็นฟ้า
    else                 color <= tile_color;
  end

endmodule
