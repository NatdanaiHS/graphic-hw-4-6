`default_nettype none

// =====================================================================
// HW5 : PPU demo
// ---------------------------------------------------------------------
// แบ่งงานเป็น 2 ส่วนเหมือนเครื่อง NES:
//   - ppu.v      = "การ์ดจอ"  วาด background + sprite ตามข้อมูลที่ได้รับ
//   - project.v  = "ตัวเกม"   (ทำหน้าที่แทน CPU) อัปเดตตำแหน่ง/ท่า ทุกเฟรม
//                  แล้วส่งค่าให้ PPU ผ่าน reg ที่เรียกว่า OAM
//
// สิ่งที่ demo นี้โชว์ (ทดสอบว่า PPU ทำงานครบ):
//   - Mario เดินซ้าย/ขวา + animation เดิน + หันหน้าตามทิศ (flip)
//   - กล้องเลื่อนตาม Mario (scroll)
//   - เหรียญหมุน (animation), Goomba เดินไปมาเอง (ขยาย 2 เท่า)
//   - Mario บังสิ่งอื่นได้ (priority) และขอบขาวโปร่งใส (transparency)
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

  // ---------------- OAM : ข้อมูลของ sprite ทุกตัว ----------------
  localparam [9:0] GROUND_Y = 352;        // Mario สูง 32 -> เท้าอยู่ที่ y=384 (พื้นในแผนที่)

  reg [10:0] mario_x;
  reg        mario_right;             // หันขวา?
  reg        mario_walking;
  reg [10:0] goomba_x;
  reg        goomba_go_right;
  reg [7:0]  frame_count;             // นับเฟรมไว้ทำ animation

  // ---------------- Game logic (ทำทุกเฟรม) ----------------
  always @(posedge clk) begin
    if (!rst_n) begin
      mario_x         <= 100;
      mario_right     <= 1;
      mario_walking   <= 0;
      goomba_x        <= 700;
      goomba_go_right <= 1;
      frame_count     <= 0;
    end else if (new_frame) begin
      frame_count <= frame_count + 1;

      // --- Mario: ปุ่มซ้าย/ขวา ---
      mario_walking <= 0;
      if (ui_in[0] && mario_x > 2) begin
        mario_x       <= mario_x - 2;
        mario_right   <= 0;
        mario_walking <= 1;
      end else if (ui_in[1] && mario_x < 1280 - 32 - 2) begin
        mario_x       <= mario_x + 2;
        mario_right   <= 1;
        mario_walking <= 1;
      end

      // --- Goomba: เดินไปกลับระหว่าง x=700..900 ---
      if (goomba_go_right) begin
        if (goomba_x >= 900) goomba_go_right <= 0;
        else                 goomba_x <= goomba_x + 1;
      end else begin
        if (goomba_x <= 700) goomba_go_right <= 1;
        else                 goomba_x <= goomba_x - 1;
      end
    end
  end

  // ท่าของ Mario: ยืน = 0 , เดิน = สลับ 1/2 ทุก 8 เฟรม
  wire [1:0] mario_frame = mario_walking ? (frame_count[3] ? 2'd2 : 2'd1) : 2'd0;

  // กล้อง: ให้ Mario อยู่กลางจอ (x=304) แต่ห้ามเลยขอบแผนที่ (0..640)
  wire [10:0] scroll_x = (mario_x < 304) ? 11'd0   :
                         (mario_x > 944) ? 11'd640 : (mario_x - 304);

  // ---------------- PPU ----------------
  wire [5:0] ppu_color;
  ppu ppu1 (
      .pix_x(pix_x), .pix_y(pix_y), .scroll_x(scroll_x),
      .mario_x(mario_x), .mario_y(GROUND_Y), .mario_frame(mario_frame), .mario_right(mario_right),
      .goomba_x(goomba_x), .goomba_y(GROUND_Y), .goomba_frame(frame_count[4]), .goomba_show(1'b1),
      .coin_frame(frame_count[4:3]),
      .coin0_x(11'd250), .coin1_x(11'd500), .coin2_x(11'd1000), .coin_y(10'd300),
      .coin_show(3'b111),
      .color(ppu_color)
  );

  always @(posedge clk)
    color <= video_active ? ppu_color : 6'd0;

endmodule
