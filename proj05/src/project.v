`default_nettype none

// =====================================================================
// HW5 : PPU demo - เดินเล่นชายหาด
// ---------------------------------------------------------------------
// แบ่งงานเป็น 2 ส่วนเหมือนเครื่อง NES:
//   - ppu.v      = "การ์ดจอ"  วาด background + sprite ตามข้อมูลที่ได้รับ
//   - project.v  = "ตัวเกม"   (ทำหน้าที่แทน CPU) อัปเดตตำแหน่ง/ท่า ทุกเฟรม
//                  แล้วส่งค่าให้ PPU (ค่าพวกนี้คือ OAM)
//
// สิ่งที่ demo นี้โชว์ (ทดสอบว่า PPU ทำงานครบ):
//   - คนเดินซ้าย/ขวา + animation เดิน + หันหน้าตามทิศ (flip)
//   - กล้องเลื่อนตามคน และ background เลื่อนแบบ parallax
//   - ปูเดินไปกลับเอง, ลูกบอลหมุน (animation)
//   - คนบังปู/ลูกบอล/ต้นมะพร้าวได้ (priority) และสีขาวโปร่งใส (transparency)
//
// ปุ่ม:  ui_in[0] = ซ้าย   ui_in[1] = ขวา
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

  // ---------------- VGA ----------------
  wire hsync, vsync, video_active;
  wire [9:0] pix_x, pix_y;
  reg  [5:0] color;

  assign uo_out  = {hsync, color[0], color[2], color[4], vsync, color[1], color[3], color[5]};
  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused_ok = &{ena, ui_in[7:2], uio_in};

  hvsync_generator vga_sync_gen (
      .clk(clk), .reset(~rst_n),
      .hsync(hsync), .vsync(vsync), .display_on(video_active),
      .hpos(pix_x), .vpos(pix_y)
  );

  wire new_frame = (pix_x == 0) && (pix_y == 480);   // 1 ครั้งต่อเฟรม

  // ---------------- OAM : ข้อมูลของ sprite ----------------
  localparam [9:0]  SAND_Y   = 384;       // sprite สูง 32 -> เท้าอยู่ที่ y=416 (บนทราย)
  localparam [10:0] CRAB_MIN = 700;       // ปูเดินไปกลับในช่วงนี้
  localparam [10:0] CRAB_MAX = 900;

  reg [10:0] player_x;
  reg        player_left;             // หันซ้าย?
  reg        player_walking;
  reg [10:0] crab_x;
  reg        crab_go_right;
  reg [7:0]  frame_count;             // นับเฟรมไว้ทำ animation

  // ---------------- Game logic (ทำทุกเฟรม) ----------------
  always @(posedge clk) begin
    if (!rst_n) begin
      player_x       <= 100;
      player_left    <= 0;
      player_walking <= 0;
      crab_x         <= CRAB_MIN;
      crab_go_right  <= 1;
      frame_count    <= 0;
    end else if (new_frame) begin
      frame_count <= frame_count + 1;

      // --- คน: ปุ่มซ้าย/ขวา (ห้ามเดินออกนอกแผนที่ 0..1248) ---
      player_walking <= 0;
      if (ui_in[0] && player_x >= 2) begin
        player_x       <= player_x - 2;
        player_left    <= 1;
        player_walking <= 1;
      end else if (ui_in[1] && player_x <= 1280 - 32 - 2) begin
        player_x       <= player_x + 2;
        player_left    <= 0;
        player_walking <= 1;
      end

      // --- ปู: เดินไปกลับเอง ---
      if (crab_go_right) begin
        if (crab_x >= CRAB_MAX) crab_go_right <= 0;
        else                    crab_x <= crab_x + 1;
      end else begin
        if (crab_x <= CRAB_MIN) crab_go_right <= 1;
        else                    crab_x <= crab_x - 1;
      end
    end
  end

  // ---------------- เลือกท่า (animation) จากตัวนับเฟรม ----------------
  wire [2:0] player_frame = !player_walking ? 3'd0 :              // ยืน
                           frame_count[3]  ? 3'd2 : 3'd1;        // เดิน: สลับทุก 8 เฟรม
  wire [2:0] crab_frame   = frame_count[3]  ? 3'd5 : 3'd4;        // ปู:   สลับทุก 8 เฟรม
  wire [2:0] ball_frame   = frame_count[4]  ? 3'd7 : 3'd6;        // บอล:  สลับทุก 16 เฟรม

  // ---------------- กล้อง ----------------
  // ให้คนอยู่กลางจอ (x=304) แต่กล้องห้ามเลยขอบแผนที่ (0..640)
  wire [10:0] scroll_x = (player_x < 304) ? 11'd0   :
                         (player_x > 944) ? 11'd640 : (player_x - 11'd304);

  // ---------------- PPU ----------------
  wire [5:0] ppu_color;
  ppu ppu1 (
      .pix_x(pix_x), .pix_y(pix_y), .scroll_x(scroll_x),
      .player_x(player_x), .player_y(SAND_Y), .player_frame(player_frame), .player_flip(player_left),
      .crab_x(crab_x), .crab_y(SAND_Y + 10'd8), .crab_frame(crab_frame), .crab_show(1'b1),
      .ball0_x(11'd250), .ball1_x(11'd520), .ball2_x(11'd1000), .ball_y(SAND_Y + 10'd16),
      .ball_frame(ball_frame), .ball_show(3'b111),
      .color(ppu_color)
  );

  always @(posedge clk)
    color <= video_active ? ppu_color : 6'd0;

endmodule
