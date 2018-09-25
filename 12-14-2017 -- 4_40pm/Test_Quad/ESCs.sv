module ESCs(clk, rst_n, frnt_spd, bck_spd, lft_spd, rght_spd, motors_off, frnt, bck, lft, rght);

input [10:0] frnt_spd, bck_spd, lft_spd, rght_spd;
input clk, rst_n, motors_off;

output frnt, bck, lft, rght;

// local paramters
localparam FRNT_OFF = 10'h220;
localparam BCK_OFF = 10'h220;
localparam LFT_OFF = 10'h220;
localparam RGHT_OFF = 10'h220;

// logics to feed into interfaces
logic [10:0] f_spd, b_spd, l_spd, r_spd;
logic [9:0] f_off, b_off, l_off, r_off;

logic [10:0] frnt_spd_ff, bck_spd_ff, lft_spd_ff, rght_spd_ff;
always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		frnt_spd_ff <= 0;
	else
		frnt_spd_ff <= frnt_spd;
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		bck_spd_ff <= 0;
	else
		bck_spd_ff <= bck_spd;
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		lft_spd_ff <= 0;
	else
		lft_spd_ff <= lft_spd;
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		rght_spd_ff <= 0;
	else
		rght_spd_ff <= rght_spd;
end
	
// produce input signals to esc interfaces
assign f_spd = frnt_spd_ff & ~motors_off;
assign b_spd = bck_spd_ff & ~motors_off;
assign l_spd = lft_spd_ff & ~motors_off;
assign r_spd = rght_spd_ff & ~motors_off;

assign f_off = FRNT_OFF & ~motors_off;
assign b_off = BCK_OFF & ~motors_off;
assign l_off = LFT_OFF & ~motors_off;
assign r_off = RGHT_OFF & ~motors_off;

// instantiate esc interfaces 4 times
ESC_interface #(18) escFrnt(.clk(clk), .rst_n(rst_n), .speed(f_spd), .off(f_off), .pwm(frnt));
ESC_interface #(18) escBck(.clk(clk), .rst_n(rst_n), .speed(b_spd), .off(b_off), .pwm(bck));
ESC_interface #(18) escLft(.clk(clk), .rst_n(rst_n), .speed(l_spd), .off(l_off), .pwm(lft));
ESC_interface #(18) escRght(.clk(clk), .rst_n(rst_n), .speed(r_spd), .off(r_off), .pwm(rght));

endmodule 