`default_nettype none

module map_rom (
    input  wire       layer,
    input  wire [6:0] col,
    input  wire [4:0] row,
    output wire [7:0] tile_id
);
  reg [7:0] mem [0:80*60-1];

  initial $readmemh("../data/beach_map.mem", mem);

  assign tile_id = mem[(layer * 30 + row) * 80 + col];
endmodule
