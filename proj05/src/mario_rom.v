`default_nettype none

// =====================================================================
// MARIO ROM : รูป Mario 4 ท่า ท่าละ 32x32  (รูปรวม 128x32)
//   frame 0 = ยืน   1,2 = เดิน   3 = กระโดด
//   รูปต้นฉบับหันหน้าไปทาง "ซ้าย"
//   สี 6'h3F (ขาว) = โปร่งใส
//
//   index = dy * 128 + frame * 32 + dx  =  { dy, frame, dx }  (5+2+5 bit)
// =====================================================================
module mario_rom (
    input  wire [1:0] frame,
    input  wire [4:0] dx,
    input  wire [4:0] dy,
    output wire [5:0] color
);
  reg [5:0] mem [0:128*32-1];
  initial $readmemh("../data/mario32j.mem", mem);
  assign color = mem[{dy, frame, dx}];
endmodule
