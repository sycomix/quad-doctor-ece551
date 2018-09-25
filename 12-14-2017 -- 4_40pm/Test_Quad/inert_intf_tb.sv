module inert_intf_tb();

logic clk, rst_n, strt_cal, INT;
logic cal_done, vld;
logic [15:0] ptch, roll, yaw;
logic MOSI, MISO, SCLK, SS_n;
logic frnt_ESC, back_ESC, left_ESC, rght_ESC;
logic [10:0] frnt_spd, bck_spd, lft_spd, rght_spd;
logic motors_off;

inert_intf iDUT1(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .INT(INT), .cal_done(cal_done), .vld(vld), .ptch(ptch), .roll(roll), .yaw(yaw), .MOSI(MOSI), .MISO(MISO), .SS_n(SS_n), .SCLK(SCLK));

CycloneIV iDUT2(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT), .frnt_ESC(frnt_ESC), .back_ESC(back_ESC), .left_ESC(left_ESC), .rght_ESC(rght_ESC));

ESCs iDUT(.clk(clk), .rst_n(rst_n), .frnt_spd(frnt_spd), .bck_spd(bck_spd), .lft_spd(lft_spd), .rght_spd(rght_spd), .motors_off(motors_off), .frnt(frnt_ESC), .bck(back_ESC), .lft(left_ESC), .rght(rght_ESC));


initial begin
clk = 0;
strt_cal = 0;
rst_n = 0;
@(posedge clk);
@(negedge clk);
rst_n = 1;

// feed in arbitrary values to cyclone, check for interrupts and vld signals
//frnt_spd = 11'h000;
frnt_spd = 11'h3FF;
bck_spd = 11'h000;
lft_spd = 11'h000;
rght_spd = 11'h000;
motors_off = 0;

@(posedge clk);
@(posedge clk);
strt_cal = 1;
@(posedge clk);
strt_cal = 0;
//@(posedge cal_done);
@(posedge vld) begin
  //$stop;
end
@(posedge cal_done);
repeat(10) @(posedge vld);
$stop;
end
always #10 clk = ~clk;

endmodule 