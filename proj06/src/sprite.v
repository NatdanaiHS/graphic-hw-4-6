`default_nettype none

module sprite (
    input  wire [10:0] world_x,
    input  wire [9:0]  y,
    input  wire [10:0] pos_x,
    input  wire [9:0]  pos_y,
    input  wire [2:0]  frame,
    input  wire        flip,
    input  wire        show,
    output wire [5:0]  color
);
  reg [5:0] mem [0:256*32-1];
  initial $readmemh("../data/sprites.mem", mem);

  wire [10:0] off_x = world_x - pos_x;
  wire [9:0]  off_y = y - pos_y;

  wire hit = show && (off_x < 32) && (off_y < 32);

  wire [4:0] dx = flip ? ~off_x[4:0] : off_x[4:0];
  wire [4:0] dy = off_y[4:0];

  assign color = hit ? mem[{dy, frame, dx}] : 6'h3F;
endmodule
