`default_nettype none

// =====================================================================
// GOOMBA ROM (Kuribo) : เดิน 2 ท่า ท่าละ 16x16  (รูปรวม 32x16)
//   index = dy * 32 + frame * 16 + dx  =  { dy, frame, dx }  (4+1+4 bit)
// =====================================================================
module goomba_rom (
    input  wire       frame,
    input  wire [3:0] dx,
    input  wire [3:0] dy,
    output wire [5:0] color
);
  reg [5:0] mem [0:32*16-1];
  initial $readmemh("../data/kuribo16j.mem", mem);
  assign color = mem[{dy, frame, dx}];
endmodule
