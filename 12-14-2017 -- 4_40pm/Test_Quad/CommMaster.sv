module CommMaster(snd_cmd, data, cmd, clk, rst_n, RX, TX, resp, resp_rdy, frm_sent, clr_resp_rdy);
// Inputs / Outputs for CommMaster
input [7:0] cmd;
input snd_cmd, RX, clk, rst_n, clr_resp_rdy;
input [15:0] data;

output logic [7:0] resp;
output logic resp_rdy, TX, frm_sent;

logic [7:0] high_byte, med_byte, low_byte, tx_data;

////////////////////////////////////////////////////////////////////////////////
// Inputs / Outputs for FSM
////////////////////////////////////////////////////////////////////////////////
// Inputs
logic snd_frm, tx_done;
// Outputs
logic [1:0] sel;
logic set_cmplt;
logic clr_cmplt;
logic trmt;
// enumeration for states for state machine
typedef enum reg [1:0] {IDLE, WAITH, WAITM, WAITL} state_fsm;   
// two states of curr_state and next_state
state_fsm curr_state, next_state;		
////////////////////////////////////////////////////////////////////////////////
// LOGIC OUTSIDE OF CONTROL STATE MACHINE / UART TRANCEIVER
////////////////////////////////////////////////////////////////////////////////

// Assign byte values to be used in Mux. 
assign high_byte = cmd[7:0];
dff_en med_dff(clk, snd_cmd, data[15:8], med_byte);
dff_en low_dff(clk, snd_cmd, data[7:0], low_byte);

// Assign byte for output value of Mux
assign tx_data = sel[1] ? high_byte : (sel[0] ? med_byte : low_byte);



		
///////////////////////////////////////////////////////////////////////////
// Instantiate UART Tranceiver
///////////////////////////////////////////////////////////////////////////	
// need clr_resp_rdy -> clr_rx_rdy(clr_rdy)
UART iTCR(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rdy(resp_rdy),.clr_rdy(clr_resp_rdy),.rx_data(resp),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done));


// STATE MACHINE ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// snd_cmd is signal used for state machine snd_frm
assign snd_frm = snd_cmd;

// FSM FLIP FLOP FOR STATE CHANGES
  	always @(posedge clk, negedge rst_n)begin
   		 if(!rst_n)
     			curr_state <= IDLE;
  		 else
      			curr_state <= next_state;
	end

////////////////////////////////////////////////////////////////////////////////
// FSM
////////////////////////////////////////////////////////////////////////////////
	always_comb begin 
	// Initialize Values for Output
   	sel[1:0] = 2'b10;
	trmt = 0;
	set_cmplt = 0;
	clr_cmplt = 0;
  

    	  case(curr_state)
		// IDLE STATE: 
     		IDLE: 
			// If snd_frm is asserted, then clr_cmplt and move to next state to send frame
			if(snd_frm) begin
				clr_cmplt = 1;
				trmt = 1;
       			 	next_state = WAITH;
     		 	end

		// WAITH STATE:
     		WAITH: 
			// Wait until transmit is complete
			if (!tx_done) begin 
				next_state = WAITH;
     			end 
			
			// Else, trans. done, send to next state and select correct byte
			else begin 
       				sel = 2'b01;
				trmt = 1;
				next_state = WAITM;
    			end

		// WAITM STATE:
		WAITM:
			// Wait until transmit of last byte is complete
			if (!tx_done) begin
				next_state = WAITM;
			end 
			
			// Else, trans. done, send to next state and select correct byte	
			else begin  
				sel = 2'b00;
				trmt = 1;
				next_state = WAITL;
     			end

		// WAITL STATE:
		WAITL:
			// Wait until transmit of last byte is complete
			if (!tx_done) begin
				next_state = WAITL;
			end 
			
			// Else, trans. done, send to next state and select correct byte	
			else begin  
				//sel = 2'b10; TODO is this necessary
				set_cmplt = 1;
				next_state = IDLE;
     			end

		// DEFAULT: next_state is START
		default: next_state = IDLE;

   	   endcase
  	end
	//FLIP FLOP for frm_sent output signal 
	always@(posedge clk, negedge rst_n)begin
		if(!rst_n) 
			frm_sent <= 0;
		else if(set_cmplt)
			frm_sent <= 1;
		else if(clr_cmplt)
			frm_sent <= 0;
		else
			frm_sent <= frm_sent;

	end
endmodule

////////////////////////////////////////////////////////////////////////////////
// Module for dff enable
////////////////////////////////////////////////////////////////////////////////
module dff_en (clk, en, d, q);
input clk, en;
input [7:0] d;
output logic [7:0] q;
always@(posedge clk) begin
	if(en)
 		q <= d;
	else
		q <= q;
end
endmodule
    

