`default_nettype none

// =====================================================================
// COIN ROM : เหรียญหมุน 4 ท่า ท่าละ 16x16  (รูปรวม 64x16)
//   index = dy * 64 + frame * 16 + dx  =  { dy, frame, dx }  (4+2+4 bit)
// =====================================================================
module coin_rom (
    input  wire [1:0] frame,
    input  wire [3:0] dx,
    input  wire [3:0] dy,
    output wire [5:0] color
);
  reg [5:0] mem [0:64*16-1];
  initial $readmemh("../data/coinj.mem", mem);
  assign color = mem[{dy, frame, dx}];
endmodule
