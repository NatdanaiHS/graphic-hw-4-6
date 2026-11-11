`timescale 1ns/1ps
// runs a scenario file "frames ui" per line with fast fake frames, then renders 1 real frame
module tb;
  reg clk=0, rst_n=0; reg [7:0] ui=0; reg pulse=0;
  wire [7:0] uo;
  tt_um_vga_example dut(.ui_in(ui),.uo_out(uo),.uio_in(8'd0),.uio_out(),.uio_oe(),.ena(1'b1),.clk(clk),.rst_n(rst_n));
  always #1 clk=~clk;
  integer sf, n, u, i, fd, r;
  reg [9:0] px1, py1; reg va1; reg rec=0;
  always @(posedge clk) begin px1<=dut.pix_x; py1<=dut.pix_y; va1<=dut.video_active; end
  always @(negedge clk) if (rec && va1) $fwrite(fd,"%0d %0d %0d\n",{uo[0],uo[4]},{uo[1],uo[5]},{uo[2],uo[6]});
  initial begin
    force dut.new_frame = pulse;
    repeat(10) @(posedge clk); rst_n=1;
    sf=$fopen("scenario.txt","r");
    while (!$feof(sf)) begin
      r=$fscanf(sf,"%d %d\n",n,u); ui=u;
      for (i=0;i<n;i=i+1) begin @(negedge clk) pulse=1; @(negedge clk) pulse=0; repeat(2) @(negedge clk); end
`ifdef GAME
      $display("after %0d ui=%0d: x=%0d y=%0d state=%0d score=%0d coins=%b goomba_alive=%0d gx=%0d", n,u,
        dut.mario_x, dut.mario_y, dut.game_state, dut.score, dut.coin_show, dut.goomba_alive, dut.goomba_x);
`else
      $display("after %0d ui=%0d", n,u);
`endif
    end
    release dut.new_frame; pulse=0;
    force dut.new_frame = 0;   // freeze game while rendering
    wait(dut.pix_x==0 && dut.pix_y==0); @(posedge clk);
    wait(dut.pix_x==0 && dut.pix_y==0);
    fd=$fopen("out.ppm","w"); $fwrite(fd,"P3\n640 480\n3\n"); rec=1;
    @(posedge clk); wait(dut.pix_x==0 && dut.pix_y==0); rec=0; $fclose(fd); $finish;
  end
endmodule
