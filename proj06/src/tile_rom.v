`default_nettype none

module tile_rom (
    input  wire [7:0] tile_id,
    input  wire [3:0] px,
    input  wire [3:0] py,
    output wire [5:0] color
);
  reg [5:0] mem [0:256*256-1];

  initial $readmemh("../data/beach_tiles.mem", mem);

  assign color = mem[{tile_id[7:4], py, tile_id[3:0], px}];
endmodule
