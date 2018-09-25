module inert_intf_test(clk, RST_n, NEXT, LED, SS_n, SCLK, MOSI, MISO, INT);


input clk, NEXT, RST_n, MISO, INT;
output logic [7:0] LED;
output logic SS_n, SCLK, MOSI;
/////////////////////////////////
/////signals for instantiations//
/////////////////////////////////
logic rst_n, released;
logic strt_cal, vld, cal_done;
logic [15:0] ptch, roll, yaw;
logic next_pb;
//////////////////////////////////
/////instantiate modules/////////
//////////////////////////////////
rst_synch my_rstn(.RST_n(RST_n), .clk(clk), .rst_n(rst_n));
PB_release my_PB(.PB(NEXT), .clk(clk), .rst_n(rst_n), .released(next_pb));
inert_intf my_inertintf(.clk(clk),.rst_n(rst_n),.MISO(MISO),.INT(INT),.strt_cal(strt_cal),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.vld(vld),.cal_done(cal_done),.ptch(ptch),.roll(roll),.yaw(yaw));

////////////////////////////////////
////signals unique to this module///
////////////////////////////////////
logic stat;
logic [1:0] sel;

//////////////////////////////////////////
typedef enum {CAL, PTCH, ROLL, YAW} states_t;
states_t state, next_state;

always_comb begin

strt_cal = 0;
sel = 2'b00;
//sel = 2'b01;
stat = 0;
next_state = CAL;
case(state)
	CAL: begin
		stat = 1;
		if(cal_done)
			next_state = PTCH;
		else begin
			strt_cal = 1;
			next_state = CAL;
		end
	end
	
	PTCH: begin
		sel = 2'b01;
		if(next_pb)
			next_state = ROLL;
		else
			next_state = PTCH;
	end

	ROLL: begin
		sel = 2'b10;
		if(next_pb)
			next_state = YAW;
		else
			next_state = ROLL;
	end

	YAW: begin
		sel = 2'b11;
		if(next_pb)
			next_state = PTCH;
		else
			next_state = YAW;
	end
endcase 
end

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= CAL;
	else
		state <= next_state;
end

always@(posedge clk) begin
if(sel == 2'b00)
	LED <= {stat, 7'h00};
else if(sel == 2'b01)
	LED <= ptch[8:1];
else if(sel == 2'b10)
	LED <= roll[8:1];
//else if(sel == 2'b11)
else
	LED <= yaw[8:1];
end

endmodule