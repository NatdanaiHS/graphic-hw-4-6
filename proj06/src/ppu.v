`default_nettype none

module ppu (
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    input  wire [10:0] scroll_x,

    input  wire [10:0] player_x,
    input  wire [9:0]  player_y,
    input  wire [2:0]  player_frame,
    input  wire        player_flip,

    input  wire [10:0] crab_x,
    input  wire [9:0]  crab_y,
    input  wire [2:0]  crab_frame,
    input  wire        crab_show,

    input  wire [10:0] ball0_x, ball1_x, ball2_x,
    input  wire [9:0]  ball_y,
    input  wire [2:0]  ball_frame,
    input  wire [2:0]  ball_show,

    output wire [5:0]  color
);
  localparam CLEAR = 6'h3F;

  wire [10:0] front_x = {1'b0, pix_x} + scroll_x;
  wire [10:0] back_x  = {1'b0, pix_x} + ((pix_y < 192) ? (scroll_x >> 2) : (scroll_x >> 1));

  wire [7:0] back_tile, front_tile;
  wire [5:0] back_color, front_color;
  map_rom  map_back    (.layer(1'b0), .col(back_x[10:4]),  .row(pix_y[8:4]), .tile_id(back_tile));
  tile_rom tiles_back  (.tile_id(back_tile),  .px(back_x[3:0]),  .py(pix_y[3:0]), .color(back_color));
  map_rom  map_front   (.layer(1'b1), .col(front_x[10:4]), .row(pix_y[8:4]), .tile_id(front_tile));
  tile_rom tiles_front (.tile_id(front_tile), .px(front_x[3:0]), .py(pix_y[3:0]), .color(front_color));

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

  assign color = (player_color != CLEAR) ? player_color :
                 (crab_color   != CLEAR) ? crab_color   :
                 (ball0_color  != CLEAR) ? ball0_color  :
                 (ball1_color  != CLEAR) ? ball1_color  :
                 (ball2_color  != CLEAR) ? ball2_color  :
                 (front_color  != CLEAR) ? front_color  :
                                           back_color;
endmodule
