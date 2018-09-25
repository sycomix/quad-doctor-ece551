//NAMES: SAMUEL RINARTZ & ADAM WEINTRAUT
module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
					roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);
				
parameter D_QUEUE_DEPTH = 14;		// delay for derivative term
				
input clk,rst_n;
input vld;									// tells when a new valid inertial reading ready
											// only update D_QUEUE on vld readings
input inertial_cal;							// need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw;	// desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw;			// actual pitch roll and yaw (from inertial interface)
input [8:0] thrst;							// thrust level from slider
output [10:0] frnt_spd;						// 11-bit unsigned speed at which to run front motor
output [10:0] bck_spd;						// 11-bit unsigned speed at which to back front motor
output [10:0] lft_spd;						// 11-bit unsigned speed at which to left front motor
output [10:0] rght_spd;						// 11-bit unsigned speed at which to right front motor

///////////////////////////////////////////////////
// Need integer for loop used to create D_QUEUE //
/////////////////////////////////////////////////
integer x;
integer y;
//////////////////////////////
// Define needed registers //
////////////////////////////								
reg signed [9:0] prev_ptch_err[0:D_QUEUE_DEPTH-1];
reg signed [9:0] prev_roll_err[0:D_QUEUE_DEPTH-1];
reg signed [9:0] prev_yaw_err[0:D_QUEUE_DEPTH-1];	// need previous error terms for D of PD

//////////////////////////////////////////////////////
// You will need a bunch of interal wires declared //
// for intermediate math results...do that here   //
///////////////////////////////////////////////////
logic signed [9:0] ptch_err_sat;
logic signed [16:0] ptch_err;
logic signed [9:0] ptch_pterm;
logic signed [9:0] ptch_D_diff;
logic signed [5:0] ptch_D_diff_sat;
logic signed [11:0] ptch_dterm;

logic signed [9:0] yaw_err_sat;
logic signed [16:0] yaw_err;
logic signed [9:0] yaw_pterm;
logic signed [9:0] yaw_D_diff;
logic signed [5:0] yaw_D_diff_sat;
logic signed [11:0] yaw_dterm;

logic signed [9:0] roll_err_sat;
logic signed [16:0] roll_err;
logic signed [9:0] roll_pterm;
logic signed [9:0] roll_D_diff;
logic signed [5:0] roll_D_diff_sat;
logic signed [11:0] roll_dterm;

logic signed [10:0] frnt_calc;
logic signed [10:0] bck_calc;
logic signed [10:0] lft_calc;
logic signed [10:0] rght_calc;

logic signed [12:0] temp_frnt_calc;
logic signed [12:0] temp_bck_calc;
logic signed [12:0] temp_lft_calc;
logic signed [12:0] temp_rght_calc;

logic signed [12:0] thrst_part;

logic signed [9:0] ptch_err_sat_ff, roll_err_sat_ff, yaw_err_sat_ff;
///////////////////////////////////////////////////////////////
// some Parameters to keep things more generic and flexible //
/////////////////////////////////////////////////////////////
  
localparam CAL_SPEED = 11'h1B0;		// speed to run motors at during inertial calibration
localparam MIN_RUN_SPEED = 13'h200;	// minimum speed while running  
localparam signed D_COEFF = 6'b00111;			// D coefficient in PID control = +7
  
  
/// OK...rest is up to you...good luck! ///
/////////////////////////////////
//pipelines for err_sat//////////
///////////////////////////////// 
always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		ptch_err_sat_ff <= 0;
	else
		ptch_err_sat_ff <= ptch_err_sat;
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		roll_err_sat_ff <= 0;
	else
		roll_err_sat_ff <= roll_err_sat;
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		yaw_err_sat_ff <= 0;
	else
		yaw_err_sat_ff <= yaw_err_sat;
end

assign ptch_err = ptch - d_ptch;
assign yaw_err = yaw - d_yaw;
assign roll_err = roll - d_roll; 

assign ptch_err_sat = (~ptch_err[16] && |ptch_err[15:9]) ? 10'h1FF : // sat pos
 			(ptch_err[16] && ~(&ptch_err[15:9])) ? 10'h200 : // sat neg
			ptch_err[9:0]; // in range

assign yaw_err_sat = (~yaw_err[16] && |yaw_err[15:9]) ? 10'h1FF : // sat pos
 			(yaw_err[16] && ~(&yaw_err[15:9])) ? 10'h200 : // sat neg
			yaw_err[9:0]; // in range

assign roll_err_sat = (~roll_err[16] && |roll_err[15:9]) ? 10'h1FF : // sat pos
 			(roll_err[16] && ~(&roll_err[15:9])) ? 10'h200 : // sat neg
			roll_err[9:0]; // in range

assign ptch_pterm = ($signed(ptch_err_sat_ff >>> 1)) + ($signed(ptch_err_sat_ff >>> 3));
assign yaw_pterm = ($signed(yaw_err_sat_ff >>> 1)) + ($signed(yaw_err_sat_ff >>> 3));
assign roll_pterm = $signed(roll_err_sat_ff >>> 1) + $signed(roll_err_sat_ff >>> 3);

assign ptch_D_diff = ptch_err_sat_ff - prev_ptch_err[D_QUEUE_DEPTH - 1];
assign yaw_D_diff = yaw_err_sat_ff - prev_yaw_err[D_QUEUE_DEPTH - 1];
assign roll_D_diff = roll_err_sat_ff - prev_roll_err[D_QUEUE_DEPTH - 1];

assign ptch_D_diff_sat = (~ptch_D_diff[9] && |ptch_D_diff[8:5]) ? 6'h1F : // sat pos
 			 (ptch_D_diff[9] && ~&ptch_D_diff[8:5]) ? 6'h20 : // sat neg
			 ptch_D_diff[5:0]; // in range

assign yaw_D_diff_sat = (~yaw_D_diff[9] && |yaw_D_diff[8:5]) ? 6'h1F : // sat pos
 			 (yaw_D_diff[9] && ~&yaw_D_diff[8:5]) ? 6'h20 : // sat neg
			 yaw_D_diff[5:0]; // in range

assign roll_D_diff_sat = (~roll_D_diff[9] && |roll_D_diff[8:5]) ? 6'h1F : // sat pos
 			 (roll_D_diff[9] && ~&roll_D_diff[8:5]) ? 6'h20 : // sat neg
			 roll_D_diff[5:0]; // in range

assign ptch_dterm = $signed(D_COEFF) * ptch_D_diff_sat; //TODO double check that this is signed multiplication, do local params need to be signed?
assign yaw_dterm = $signed(D_COEFF) * yaw_D_diff_sat; //TODO double check that this is signed multiplication, do local params need to be signed?
assign roll_dterm = $signed(D_COEFF) * roll_D_diff_sat; //TODO double check that this is signed multiplication, do local params need to be signed?


always_ff@(posedge clk, negedge rst_n)begin
	if(!rst_n)begin 
		for(x = 0 ; x < D_QUEUE_DEPTH; x = x + 1)begin
			prev_ptch_err[x] = 10'd0;
			prev_yaw_err[x] = 10'd0;
			prev_roll_err[x] = 10'd0;
		end
	end
	else if(vld)begin
		for(y = D_QUEUE_DEPTH - 1; y > 0; y = y - 1)begin
			prev_ptch_err[y] = prev_ptch_err[y - 1];
			prev_yaw_err[y] = prev_yaw_err[y - 1];
			prev_roll_err[y] = prev_roll_err[y - 1];
		end
		prev_ptch_err[0] = ptch_err_sat_ff;
		prev_yaw_err[0] = yaw_err_sat_ff;
		prev_roll_err[0] = roll_err_sat_ff;

	end



end
assign thrst_part = {4'b0000, thrst[8:0]};
assign temp_frnt_calc = thrst_part + MIN_RUN_SPEED - {{3{ptch_pterm[9]}}, ptch_pterm[9:0]} - {ptch_dterm[11], ptch_dterm[11:0]} - {{3{yaw_pterm[9]}}, yaw_pterm[9:0]} - {yaw_dterm[11], yaw_dterm[11:0]};
assign temp_bck_calc = thrst_part + MIN_RUN_SPEED + {{3{ptch_pterm[9]}}, ptch_pterm[9:0]} + {ptch_dterm[11], ptch_dterm[11:0]} - {{3{yaw_pterm[9]}}, yaw_pterm[9:0]} - {yaw_dterm[11], yaw_dterm[11:0]};
assign temp_lft_calc = thrst_part + MIN_RUN_SPEED - {{3{roll_pterm[9]}}, roll_pterm[9:0]} - {roll_dterm[11], roll_dterm[11:0]} + {{3{yaw_pterm[9]}}, yaw_pterm[9:0]} + {yaw_dterm[11], yaw_dterm[11:0]};
assign temp_rght_calc = thrst_part + MIN_RUN_SPEED + {{3{roll_pterm[9]}}, roll_pterm[9:0]} + {roll_dterm[11], roll_dterm[11:0]} + {{3{yaw_pterm[9]}}, yaw_pterm[9:0]} + {yaw_dterm[11], yaw_dterm[11:0]};


assign frnt_calc = (temp_frnt_calc[12]) ? 11'd0:
			(temp_frnt_calc > 11'h7FF) ? 11'h7FF:
			{temp_frnt_calc[10:0]};

assign bck_calc = (temp_bck_calc[12]) ? 11'd0:
			(temp_bck_calc > 11'h7FF) ? 11'h7FF:
			{temp_bck_calc[10:0]};

assign lft_calc = (temp_lft_calc[12]) ? 11'd0:
			(temp_lft_calc > 11'h7FF) ? 11'h7FF:
			{temp_lft_calc[10:0]};

assign rght_calc = (temp_rght_calc[12]) ? 11'd0:
			(temp_rght_calc > 11'h7FF) ? 11'h7FF:
			{temp_rght_calc[10:0]};


assign frnt_spd = (inertial_cal) ? CAL_SPEED:
		frnt_calc;

assign bck_spd = (inertial_cal) ? CAL_SPEED:
		bck_calc;

assign lft_spd = (inertial_cal) ? CAL_SPEED:
		lft_calc;

assign rght_spd = (inertial_cal) ? CAL_SPEED:
		rght_calc;



  
endmodule 
