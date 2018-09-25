module cmd_cfg_tb();

/////////////////////////////////////
///////SIGNALS///////////////////////
/////////////////////////////////////
logic RX_TX, TX_RX, snd_resp, clk, rst_n;
logic [7:0] cmd, resp;
logic [15:0] data;
logic cmd_rdy, resp_sent, clr_cmd_rdy, snd_cmd, resp_rdy, frm_sent;

//cmd_cfg
logic [15:0] d_ptch, d_roll, d_yaw;
logic [7:0] batt;
logic [8:0] thrst;
logic strt_cal, inertial_cal, cal_done, motors_off, strt_cnv, cnv_cmplt;
localparam REQ_BATT = 8'h01, SET_PTCH = 8'h02, SET_ROLL = 8'h03, SET_YAW = 8'h04, SET_THRST = 8'h05, CALIBRATE = 8'h06,  EMER_LAND = 8'h07, MTRS_OFF = 8'h08;
//
logic [7:0] cm_cmd;
logic [15:0] cm_data;
logic [7:0] cm_resp; 
localparam POS_ACK = 8'hA5;
/////////////////////////////////////
//////Instantiate modules////////////
/////////////////////////////////////

// UNSURE ABOUT MODULE SIGNALS - ADAM
// Is the output from resp_rdy and frm_sent for commMaster supposed to correspond to inputs of other modules ??
UART_wrapper wrapper(.RX(TX_RX), .TX(RX_TX), .cmd(cmd), .data(data), .resp(resp), .clr_cmd_rdy(clr_cmd_rdy), .cmd_rdy(cmd_rdy), .snd_resp(snd_resp), .resp_sent(resp_sent), .clk(clk), .rst_n(rst_n));
cmd_cfg command(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data), .clr_cmd_rdy(clr_cmd_rdy), .resp(resp), .send_resp(snd_resp), .d_ptch(d_ptch), .d_roll(d_roll), .d_yaw(d_yaw), .thrst(thrst), .batt(batt), .strt_cal(strt_cal), .inertial_cal(inertial_cal), .cal_done(cal_done), .motors_off(motors_off), .strt_cnv(strt_cnv), .cnv_cmplt(cnv_cmplt));
CommMaster commMaster(.snd_cmd(snd_cmd), .data(cm_data), .cmd(cm_cmd), .clk(clk), .rst_n(rst_n), .RX(RX_TX), .TX(TX_RX), .resp(cm_resp), .resp_rdy(resp_rdy), .frm_sent(frm_sent));
////////////////////////////////////
//////TEST BENCH////////////////////
////////////////////////////////////
initial begin
clk = 0;
rst_n = 0;
cnv_cmplt = 0;
@(posedge clk);
@(negedge clk);
@(posedge clk);
rst_n = 1;
batt = 8'hCF;
@(posedge clk);


//check command1
task_send_cmd(REQ_BATT,16'h1234);
task_check_batt();
// check command2
task_send_cmd(SET_PTCH,16'h1234);
check_response(POS_ACK);
task_check_ptch(16'h1234);
// check command3
task_send_cmd(SET_ROLL,16'h1234);
check_response(POS_ACK);
task_check_roll(16'h1234);
//check command4
task_send_cmd(SET_YAW,16'h1234);
check_response(POS_ACK);
task_check_yaw(16'h1234);
//check command5
task_send_cmd(SET_THRST,16'h0123);
check_response(POS_ACK);
task_check_thrst(9'h123);
//check command6
task_send_cmd(CALIBRATE,16'h178);
$stop;
wait134sec();   //check motors_on and strt_cal in this function as well 
@(posedge clk);
@(negedge clk);
check_inertial_cal(1'b1);
@(posedge clk);
cal_done=1;
@(posedge clk);
@(negedge clk);
cal_done=0;
@(posedge clk);
check_inertial_cal(1'b0);
check_response(POS_ACK);
@(posedge clk);
@(negedge clk);
check_motors_on();
//check command7
task_send_cmd(EMER_LAND,16'h178);
check_response(POS_ACK);
task_check_emer_land();
//check command8
task_send_cmd(MTRS_OFF,16'h178);
check_response(POS_ACK);
task_motors_off();

$display("Test Passed");
$stop;

end

always #5 clk = ~clk;



// Takes in cmd2, data2 as input, sends using commMaster 
task task_send_cmd;
// inputs
input [7:0] cmd2;
input [15:0] data2;
begin
cm_cmd = cmd2; //assign inputs to the commMaster
cm_data = data2;
snd_cmd =1;  //signal CommMaster to send

$display("sending cmd, data  %h,%h",cm_cmd,cm_data);  // these were my commMaster cmd and data signals
@(posedge clk);
snd_cmd=0;  //reset send_cmd so it doesn't resend after completion
@(posedge clk);
end
endtask


task check_response;
input POS_ACK;
begin
	@(posedge resp_rdy);
	$display("Acknowledge received: %h", resp);

end
endtask

task wait134sec;
begin
	@(posedge strt_cal);
	$stop;
	check_motors_on();

end
endtask

task check_motors_on;
begin
	$display("motors_off: %h", motors_off);
	if(motors_off)begin
		$display("motors should be on");
		$stop;
	end
end
endtask

task check_inertial_cal;
input val;
begin
	if(inertial_cal != val)begin
		$display("inertial cal not equal to val: %h", inertial_cal);
		$stop;
	end
	else
		$display("inertial_cal pass");

end
endtask

// task to check the pitch
task task_check_ptch;
//inputs
input [15:0] ptch;
begin
 if(ptch != d_ptch) begin
    $display("Pitch Incorrect! Pitch sent = %h, Pitch output = %h", ptch, d_ptch);
    $stop;
 end
 else 
    $display("Pitch Correct! Pitch sent = %h, Pitch output = %h", ptch, d_ptch);
  
end
endtask

// task to check the roll
task task_check_roll;
//inputs
input [15:0] roll;
begin
  if(roll != d_roll) begin
    $display("Roll Incorrect! Roll sent = %h, Roll output = %h", roll, d_roll);
    $stop;
  end 
  else
    $display("Roll Correct! Roll sent = %h, Roll output = %h", roll, d_roll);
  
end
endtask

// task to check the yaw
task task_check_yaw;
//inputs
input [15:0] yaw;
begin
  if(yaw != d_yaw) begin
    $display("Yaw Incorrect! Yaw sent = %h, Yaw output = %h", yaw, d_yaw);
    $stop;
  end
 else
    $display("Yaw Correct! Yaw sent = %h, Yaw output = %h", yaw, d_yaw);
 

end
endtask

// task to check the thrust
task task_check_thrst;
//inputs
input [8:0] s_thrst;
begin
if(s_thrst != thrst) begin
    $display("Thrust Incorrect! Thrust sent = %h, Thrust output = %h", s_thrst, thrst);
    $stop;
  end 
else
    $display("Thrust Correct! Thrust sent = %h, Thrust output = %h", s_thrst, thrst);
  
end
endtask

// task to check emergency landing
task task_check_emer_land;
//inputs
begin
  if(d_ptch != 0 || d_yaw != 0 || d_roll != 0 || thrst != 0) begin
    $display("Emergency Landing Incorrect! Roll = %h, Yaw = %h, Pitch = %h, Thrust = %h", d_roll, d_yaw, d_ptch, thrst);
    $stop;
  end
 else
    $display("Emergency Landing Correct! Roll = %h, Yaw = %h, Pitch = %h, Thrust = %h", d_roll, d_yaw, d_ptch, thrst);
  
end
endtask

// task to check reqeust batt
task task_check_batt;
begin
  @(posedge cmd_rdy);
  @(posedge clk);
  @(negedge clk);
  cnv_cmplt = 1;
  @(posedge clk);
  @(negedge clk);
  cnv_cmplt = 0;
  @(posedge resp_rdy);
  if(batt != cm_resp) begin
    $display("Batt Request Incorrect! Batt input = %h, Response = %h", batt, cm_resp);
    $stop;
  end 
else 
    $display("Batt Request Correct! Batt input = %h, Response = %h", batt, resp);
  
end
endtask

task task_motors_off;
begin
if(motors_off)begin
  $display("Test Passed, motors are off");
end
else begin
  $display("Test failed, expected motors_off to be asserted");
  $stop;
end
end
endtask



endmodule
