module QuadCopter_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;
wire SS_A2D_n,SCLK_A2D,MOSI_A2D,MISO_A2D;
wire RX,TX;
wire [7:0] resp;				// response from DUT
wire cmd_sent,resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd_to_copter;		// command to Copter via wireless link
reg [15:0] data;				// data associated with command
reg send_cmd;					// asserted to initiate sending of command (to your CommMaster)
reg clr_resp_rdy;				// asserted to knock down resp_rdy
reg frm_sent;
/////// declare any localparams here /////
reg [31:0] posedge_time;
reg [31:0] negedge_time;
reg [31:0] pulse_time;
reg [7:0] actual_pwm;
reg [8:0] pwm1;
reg [8:0] pwm2;
reg [8:0] leftAndRight;
reg [8:0] frontAndBack;

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT),
                .frnt_ESC(frnt_ESC),.back_ESC(back_ESC),.left_ESC(left_ESC),
				.rght_ESC(rght_ESC));				  

///////////////////////////////////////////////////
// Instantiate Model of A2D for battery voltage //
/////////////////////////////////////////////////
ADC128S iA2D(.clk(clk),.rst_n(RST_n),.SS_n(SS_A2D_n),.SCLK(SCLK_A2D),
             .MISO(MISO_A2D),.MOSI(MOSI_A2D));			
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.LED(),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC),.SS_A2D_n(SS_A2D_n),.SCLK_A2D(SCLK_A2D),
				.MOSI_A2D(MOSI_A2D),.MISO_A2D(MISO_A2D));

//module CommMaster(clk, rst_n, cmd, snd_cmd, data, resp, resp_rdy, TX, RX);
//// Instantiate Master UART (used to send commands to Copter) //////
CommMaster iMSTR(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                 .cmd(cmd_to_copter), .data(data), .snd_cmd(send_cmd),
			     .frm_sent(cmd_sent), .resp_rdy(resp_rdy),
				 .resp(resp), .clr_resp_rdy(clr_resp_rdy));

localparam REQ_BATT = 8'h01, SET_PTCH = 8'h02, SET_ROLL = 8'h03, SET_YAW = 8'h04, SET_THRST = 8'h05, CALIBRATE = 8'h06,  EMER_LAND = 8'h07, MTRS_OFF = 8'h08;
initial begin


initialize();

// Calibrate and confirm POS ACK
check_calibrate();

// Check Battery and confirm that we receive battery value
check_req_batt();


// Set thrust to max by saturating (ffff)
// Set thrust to min (0)
// Check that PWM levels are correct
check_thrust();



// Set Pitch
// Check it converges to right value
// Check the PWM values
check_set_pitch();

// Set Roll
// Check it converges to right value
// Check the PWM values
check_set_roll();

// Set Yaw
// Check it converges to right value
// Check the PWM values
check_set_yaw();
	

// Set Emergency Landing
// Check that ptch roll and yaw are set to 0
// Checks that they converge to 0
check_emer_land();


// Set Motors Off
// Check that PWM is correct
check_motors_off();


$display("TESTS PASSED!!!");
$stop;	

end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// END 
// 	 OF
//		TESTING
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////








///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Initialize
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task initialize;
begin
	$display("---------------------------------------");
	$display("Initializing....");
	clk=0;
	@(posedge clk);
	RST_n=0;
	@(posedge clk);
	RST_n =1;
	@(posedge iDUT.iRST.rst_n);
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Calibration (for POS ACK)
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_calibrate;
begin
	$display("---------------------------------------");
	$display("Calibrating....");
	send_command(CALIBRATE, 16'h03ff);
end
endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Request Battery (for Correct Battery Level)
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_req_batt;
begin
	$display("---------------------------------------");
	$display("Requesting Battery Level....");
	send_command(REQ_BATT, 16'h0000);
end
endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Set Pitch (Positive Change)
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_set_pitch;
begin
	$display("---------------------------------------");
	$display("Setting the Ptch....");
	send_command(SET_PTCH, 16'h0000);
	repeat(15)@(posedge frnt_ESC);
	//check_convergence_ptch();
	send_command(SET_PTCH, 16'h005f);
	check_convergence_ptch();
	check_pwm_ptch();
end
endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Set Roll (Positive Change)
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_set_roll;
begin
	
	send_command(SET_ROLL, 16'h0000);
	repeat(15)@(posedge rght_ESC);
	//check_convergence_roll();
	send_command(SET_ROLL, 16'h005f);
	check_convergence_roll();
	check_pwm_roll();
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Set Yaw (Positive Change)
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_set_yaw;
begin
	send_command(SET_YAW, 16'h0000);
	repeat(15)@(posedge frnt_ESC);
	//check_convergence_yaw();
	send_command(SET_YAW, 16'h005f);
	check_convergence_yaw();
	check_pwm_yaw();
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Emergency Landing
// inputs:
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_emer_land;
begin
	send_command(EMER_LAND, 16'h0000);
	if(!iDUT.ifly.d_yaw && !iDUT.ifly.d_ptch && !iDUT.ifly.d_roll) begin
		check_convergence_ptch();
		check_convergence_roll();
		check_convergence_yaw();
	end
	else begin
		$display("Either yaw, ptch, or roll haven't been set to 0");
	end
end
endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Send Motors Off
// inputs: cmd, data
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_motors_off;
begin
	send_command(MTRS_OFF, 16'h0000);
	// 8'h87 == 135
	check_pwm_frnt(8'd135);
	check_pwm_back(8'd135);
	check_pwm_rght(8'd135);
	check_pwm_left(8'd135);
end
endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Send Command
// inputs: cmd, data
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task send_command;
//inputs
input [7:0] input_cmd;
input [15:0] input_data;
begin
	cmd_to_copter = input_cmd;
	data = input_data;
	send_cmd = 1;
	$display("Sending cmd: %h with data: %h",cmd_to_copter,data);
	@(posedge clk)
	send_cmd = 0;
	if(input_cmd == 8'h01)
		check_battery();
	else
		check_response(8'hA5);
end
endtask 

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Battery
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_battery;
begin 
	@(posedge resp_rdy);
	if(resp == 8'hA5) begin
		$display("Resp asserted acknowledge: %h", resp);
		$stop();
	end
	else if(resp == 8'hC0) begin
		$display("Battery Level is correct: %h", resp);
		
	end
	else begin
		$display("Battery Level is at: %h", resp);
		$stop();
	end
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Response (for Acknowledge)
// inputs: POS_ACK (0xA5)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_response;
input [7:0] POS_ACK;
begin
	@(posedge resp_rdy);
	if(resp != POS_ACK)begin
		$display("Acknowledge incorrect, resp = %h", resp);
		$stop;
	end
	$display("Acknowledge Received: %h", resp);

end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check Thrust
// inputs: NONE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_thrust;
begin
	// Set Thrust to Max (Through Saturation)
	// PWM should be around 1.50 ms at max running speed
	send_command(SET_THRST, 16'hffff);
	check_pwm_frnt(8'd150);
	check_pwm_back(8'd150);
	check_pwm_left(8'd150);
	check_pwm_rght(8'd150);

	// Set Thrust to Min
	// PWM should be around 1.35 ms at min running speed
	send_command(SET_THRST, 16'h0000);
	check_pwm_frnt(8'd135);
	check_pwm_back(8'd135);
	check_pwm_left(8'd135);
	check_pwm_rght(8'd135);
			

end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GENERATE PWM VALUE 
// FRONT
// inputs: expected_pwm 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_pwm_frnt;

input [7:0] expected_pwm;

begin
	$display("Testing frnt_ESC");
	@(posedge frnt_ESC);
	posedge_time = $time;
	@(negedge frnt_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	compare_pwm(expected_pwm, actual_pwm);
	
end
endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHECK PWM  
// PTCH
// inputs:  
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_pwm_ptch;
begin
	$display("Checking ptch !");
	@(posedge frnt_ESC);
	posedge_time = $time;
	@(negedge frnt_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm1 = {{1'b0},actual_pwm};
	
	@(posedge back_ESC);
	posedge_time = $time;
	@(negedge back_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm2 = {{1'b0},actual_pwm};

	$display("ptch: frnt_ESC: %d e-5 s, back_ESC: %d e-5 s", pwm1, pwm2);
	
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHECK PWM  
// ROLL
// inputs: 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_pwm_roll;
begin
	$display("Checking roll !");
	@(posedge left_ESC);
	posedge_time = $time;
	@(negedge left_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm1 = {{1'b0},actual_pwm};
	
	@(posedge rght_ESC);
	posedge_time = $time;
	@(negedge rght_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm2 = {{1'b0},actual_pwm};

	$display("roll: left_ESC: %d e-5 s, rght_ESC: %d e-5 s", pwm1, pwm2);

end
endtask
	

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHECK PWM  
// ROLL
// inputs: 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_pwm_yaw;
begin
	$display("Checking yaw !");
	@(posedge left_ESC);
	posedge_time = $time;
	@(negedge left_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm1 = {{1'b0},actual_pwm};
	
	@(posedge rght_ESC);
	posedge_time = $time;
	@(negedge rght_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm2 = {{1'b0},actual_pwm};
	$display("yaw: left_ESC: %d e-5 s, rght_ESC: %d e-5 s", pwm1, pwm2);
	leftAndRight = pwm1 + pwm2;

	@(posedge frnt_ESC);
	posedge_time = $time;
	@(negedge frnt_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm1 = {{1'b0},actual_pwm};
	
	@(posedge back_ESC);
	posedge_time = $time;
	@(negedge back_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get 100s-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm = pulse_time / 20'h02710;
	pwm2 = {{1'b0},actual_pwm};
	$display("yaw: frnt_ESC: %d e-5 s, back_ESC: %d e-5 s", pwm1, pwm2);
	frontAndBack = pwm1 + pwm2;

	$display("yaw: (l + r) <= (f + b): (l + r): %d, (f + b): %d", leftAndRight, frontAndBack);
	
end
endtask
	


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GENERATE PWM VALUE 
// BACK
// inputs: expected_pwm 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_pwm_back;

input [7:0] expected_pwm;

begin
	$display("Testing back_ESC");
	@(posedge back_ESC);
	posedge_time = $time;
	@(negedge back_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get tens-of-ms to compare
	// expected should be in range of 100-200, 
	// instead of 1.5 ms since we will use int division
	actual_pwm <= pulse_time / 20'h02710;
	compare_pwm(expected_pwm, actual_pwm);
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GENERATE PWM VALUE 
// LEFT
// inputs: expected_pwm 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_pwm_left;

input [7:0] expected_pwm;

begin
	$display("Testing left_ESC");
	@(posedge left_ESC);
	posedge_time = $time;
	@(negedge left_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 100,000 to get tens-of-ms to compare
	// expected should be in range of 10-20, 
	// instead of 1.5 ms since we will use int division
	actual_pwm <= pulse_time / 20'h02710;
	compare_pwm(expected_pwm, actual_pwm);
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GENERATE PWM VALUE 
// RIGHT
// inputs: expected_pwm 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

task check_pwm_rght;

input [7:0] expected_pwm;

begin
	$display("Testing rght_ESC");
	@(posedge rght_ESC);
	posedge_time = $time;
	@(negedge rght_ESC);
	negedge_time = $time;
	pulse_time = negedge_time - posedge_time;
	// Divide by 10,000 to get tens-of-ms to compare
	// expected should be in range of 10-20, 
	// instead of 1.5 ms since we will use int division
	actual_pwm <= pulse_time / 20'h02710;
	compare_pwm(expected_pwm, actual_pwm);
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// COMPARE PWM VALUES
// inputs: expected_pwm, actual_pwm
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task compare_pwm;

input [7:0] expected_pwm;
input [7:0] actual_pwm;
begin
	if(actual_pwm > (expected_pwm + 5)) begin
		$display("Too High: %d e-5 s, should be around %d e-5 s", actual_pwm, expected_pwm);
		$stop();
	end
	else if(actual_pwm < (expected_pwm - 5)) begin
		$display("Too Low: %d e-5s, should be around %d e-5 s", actual_pwm, expected_pwm);
		$stop();
	end
	else begin
		$display("PWM looks about right: %d e-5 s, should be around %d e-5 s", actual_pwm, expected_pwm);
	end
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHECK CONVERGENCE 
// PTCH
// inputs: 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_convergence_ptch;
begin
	while ( !(($signed(iDUT.ifly.d_ptch - iDUT.ifly.ptch) > -2) && ($signed(iDUT.ifly.d_ptch - iDUT.ifly.ptch) < 2))) begin
		@(posedge clk);
	end
	$display("Successfully converged: d_ptch: %h ptch: %h", iDUT.ifly.d_ptch, iDUT.ifly.ptch);
end
endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHECK CONVERGENCE 
// ROLL
// inputs: 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_convergence_roll;
begin
	while ( !(($signed(iDUT.ifly.d_roll - iDUT.ifly.roll) > -2) && ($signed(iDUT.ifly.d_roll - iDUT.ifly.roll) < 2))) begin
		@(posedge clk);
	end
	$display("Successfully converged: d_roll: %h roll: %h", iDUT.ifly.d_roll, iDUT.ifly.roll);
end
endtask
	

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHECK CONVERGENCE 
// YAW
// inputs: 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_convergence_yaw;
begin
	while ( !(($signed(iDUT.ifly.d_yaw - iDUT.ifly.yaw) > -2) && ($signed(iDUT.ifly.d_yaw - iDUT.ifly.yaw) < 2))) begin
		@(posedge clk);
	end
	$display("Successfully converged: d_yaw: %h yaw: %h", iDUT.ifly.d_yaw, iDUT.ifly.yaw);
end
endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CLOCK INSTANTIAION
always
  #10 clk = ~clk;

//`include "tb_tasks.v"	// maybe have a separate file with tasks to help with testing

endmodule	


