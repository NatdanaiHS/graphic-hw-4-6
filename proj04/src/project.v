`default_nettype none

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

  wire hsync, vsync, video_active;
  wire [9:0] pix_x, pix_y;
  reg  [5:0] color;

  assign uo_out  = {hsync, color[0], color[2], color[4], vsync, color[1], color[3], color[5]};
  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused_ok = &{ena, ui_in[7:3], uio_in};

  hvsync_generator vga_sync_gen (
      .clk(clk), .reset(~rst_n),
      .hsync(hsync), .vsync(vsync), .display_on(video_active),
      .hpos(pix_x), .vpos(pix_y)
  );

  localparam MAP_W       = 1280;
  localparam TRANSPARENT = 6'h3F;

  function [10:0] wrap_add(input [10:0] a, input [10:0] b);
    wrap_add = (a + b >= MAP_W) ? (a + b - MAP_W) : (a + b);
  endfunction

  reg [10:0] scroll_cloud;
  reg [10:0] scroll_sea;
  reg [10:0] scroll_beach;

  wire go_left  = ui_in[0];
  wire go_right = ui_in[1] | ui_in[2];

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

  wire [10:0] back_x  = wrap_add(pix_x, (pix_y < 192) ? scroll_cloud : scroll_sea);
  wire [10:0] front_x = wrap_add(pix_x, scroll_beach);

  wire [7:0] back_tile;
  wire [5:0] back_color;
  map_rom  map_back   (.layer(1'b0), .col(back_x[10:4]), .row(pix_y[8:4]), .tile_id(back_tile));
  tile_rom tiles_back (.tile_id(back_tile), .px(back_x[3:0]), .py(pix_y[3:0]), .color(back_color));

  wire [7:0] front_tile;
  wire [5:0] front_color;
  map_rom  map_front   (.layer(1'b1), .col(front_x[10:4]), .row(pix_y[8:4]), .tile_id(front_tile));
  tile_rom tiles_front (.tile_id(front_tile), .px(front_x[3:0]), .py(pix_y[3:0]), .color(front_color));

  always @(posedge clk) begin
    if (!video_active)                   color <= 0;
    else if (front_color != TRANSPARENT) color <= front_color;
    else                                 color <= back_color;
  end

endmodule
