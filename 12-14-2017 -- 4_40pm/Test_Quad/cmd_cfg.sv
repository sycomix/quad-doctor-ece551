module cmd_cfg(clk, rst_n, cmd_rdy, cmd, data, clr_cmd_rdy, resp, send_resp, d_ptch, d_roll, d_yaw, thrst, batt, strt_cal, inertial_cal, cal_done, motors_off, strt_cnv, cnv_cmplt);

input clk, rst_n, cmd_rdy, cal_done, cnv_cmplt;
input [7:0] cmd;
input [15:0] data;
input [7:0] batt;

// boolean
logic send_batt;

output logic clr_cmd_rdy, send_resp, strt_cal, inertial_cal, motors_off, strt_cnv;
output logic [7:0] resp;
output logic signed [15:0] d_ptch, d_roll, d_yaw; //TODO should this be signed caused errors last time
output logic unsigned [8:0] thrst;

localparam REQ_BATT = 8'h01, SET_PTCH = 8'h02, SET_ROLL = 8'h03, SET_YAW = 8'h04, SET_THRST = 8'h05, CALIBRATE = 8'h06,  EMER_LAND = 8'h07, MTRS_OFF = 8'h08;
//TODO Emergency land sets all 4 things to zero

typedef enum {IDLE, SEND_BATT, SET_VALS, MOTOR_OFF, CALIBRATE_MOTORS, WAIT} state_t;
state_t state, nxt_state;
// assign response to correct value dependent on whether we make pos
// change or to give the battery signal

assign resp = send_batt ? batt : 8'hA5;


//////////////////////////////////////////////////////////////////
/////////Sam Additions///////////////////////////////////////////
/////////////////////////////////////////////////////////////////
logic wrt_ptch, wrt_roll, wrt_yaw, wrt_thrst, set_emer_land;
logic en_mtrs;
logic clr_timer;
logic set_motors_off, tmr_full;
logic resp_sent;
logic RX, TX;
logic [25:0] counter;
logic set_inertial_cal, clr_inertial_cal;
//Changed cmd_signal from an enum to localparams
//Changed wroll to wrt_roll in flops
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		counter <= 0;
	else if(clr_timer)
		counter <= 0;
	else
		counter <= counter + 1;
end

assign tmr_full = counter == 26'h3FFFFFF;
////////////////////////////////////////////////////////////////////
// d_ptch flop
////////////////////////////////////////////////////////////////////
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		d_ptch <= 16'h0000;
	else if(set_emer_land)
		d_ptch <= 16'h0000;
	else if(wrt_ptch)
		d_ptch <= data;
	else
		d_ptch <= d_ptch;
end

////////////////////////////////////////////////////////////////////
// d_roll flop
////////////////////////////////////////////////////////////////////
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		d_roll <= 16'h0000;
	else if(set_emer_land)
		d_roll <= 16'h0000;
	else if(wrt_roll)
		d_roll <= data;
	else
		d_roll <= d_roll;
end


////////////////////////////////////////////////////////////////////
// d_yaw flop
////////////////////////////////////////////////////////////////////
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		d_yaw <= 16'h0000;
	else if(set_emer_land)
		d_yaw <= 16'h0000;
	else if(wrt_yaw)
		d_yaw <= data;
	else
		d_yaw <= d_yaw;
end


////////////////////////////////////////////////////////////////////
// thrst flop
////////////////////////////////////////////////////////////////////
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		thrst <= 9'h000;
	else if(set_emer_land)
		thrst <= 9'h000;
	else if(wrt_thrst)
		thrst <= {data[8:0]};
	else
		thrst <= thrst;
end


////////////////////////////////////////////////////////////////////
// MOTORS flop  
////////////////////////////////////////////////////////////////////
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		motors_off <= 1;
	else if(set_motors_off)
		motors_off <= 1;
	else if(en_mtrs)
		motors_off <= 0;
	else 
		motors_off <= motors_off;
end







//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 						STATE MACHINE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
// FSM FLOP
////////////////////////////////////////////////////////////////////
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end



////////////////////////////////////////////////////////////////////
// FSM
////////////////////////////////////////////////////////////////////
always_comb begin
en_mtrs = 0;
send_batt = 0;
send_resp = 0;
wrt_ptch = 0;
wrt_roll = 0;
wrt_yaw = 0;
wrt_thrst = 0;
strt_cal = 0;
clr_timer = 0;
set_motors_off = 0;
strt_cnv = 0;
clr_cmd_rdy = 0;
set_emer_land = 0;
set_inertial_cal = 0;
clr_inertial_cal = 0;
nxt_state = IDLE;


case(state)
	// Command Dispatch State
	IDLE: begin
		if(cmd_rdy) begin
			clr_cmd_rdy = 1;
			case(cmd)
				REQ_BATT: begin
					strt_cnv = 1;
					nxt_state = SEND_BATT;
				end
				SET_PTCH: begin
					wrt_ptch = 1;
					nxt_state = SET_VALS;
				end
				SET_ROLL: begin
					wrt_roll = 1;
					nxt_state = SET_VALS;
				end
				SET_YAW: begin
					wrt_yaw = 1;
					nxt_state = SET_VALS;
				end
				SET_THRST: begin
					wrt_thrst = 1;
					nxt_state = SET_VALS;
				end
				EMER_LAND: begin
					set_emer_land = 1;
					nxt_state = SET_VALS;
				end
				MTRS_OFF: begin
					set_motors_off = 1;
					nxt_state = MOTOR_OFF;
				end
				CALIBRATE: begin
					en_mtrs = 1;
					nxt_state = WAIT;
					clr_timer = 1;
					set_inertial_cal = 1;//TODO possible set location
				end
			endcase
		end
	end
	SEND_BATT: begin
		send_batt = 1;//TODO should this go above the if statement?
		if(cnv_cmplt) begin
			send_resp = 1;
			nxt_state = IDLE;
		end
		else begin
			nxt_state = SEND_BATT;
		end
	end
	SET_VALS: begin
		send_resp = 1;
		nxt_state = IDLE;
	end
	MOTOR_OFF: begin
		set_motors_off = 1;
		send_resp = 1;
		nxt_state = IDLE;
	end
	WAIT: begin 
		if(tmr_full)begin
			nxt_state = CALIBRATE_MOTORS;
			strt_cal = 1;
		end
		else begin
			nxt_state = WAIT;
			en_mtrs = 1;//TODO why is this necessary?
			//TODO possible set location
		end
	end
	CALIBRATE_MOTORS: begin
		if(cal_done) begin
		  send_resp = 1;
		  nxt_state = IDLE;
		  clr_inertial_cal = 1;//TODO possible clr location
			//TODO why was set here?
		end
		else begin
			nxt_state = CALIBRATE_MOTORS;
		end

	end
	
	

endcase

end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		inertial_cal <= 0;
	else if(set_inertial_cal)
		inertial_cal <= 1;
	else if(clr_inertial_cal)
		inertial_cal <= 0;
	else
		inertial_cal <= inertial_cal;
end




endmodule 