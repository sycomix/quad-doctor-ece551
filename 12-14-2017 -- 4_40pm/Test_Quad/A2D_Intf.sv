//TEAM: QuadDoctors
//NAMES: Samuel Rinartz, Adam Weintraut

module A2D_intf(clk, rst_n, strt_cnv, chnnl, cnv_cmplt, res, SS_n, SCLK, MOSI, MISO);

///////////////////////////////////////////////////
////INPUTS AND OUTPUTS////////////////////////////
///////////////////////////////////////////////////
input [2:0] chnnl;
input strt_cnv, clk, rst_n, MISO;
output logic cnv_cmplt, SS_n, SCLK, MOSI;
output logic [11:0] res;
/////////////////////////////////////////////////
logic [15:0] rd_data;
logic fsm_complete;
logic wrt;
logic done;
/////////////////////////////////////////////////
assign res = rd_data[11:0];

SPI_mstr16 SPI_int(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .cmd({2'b00, chnnl, 11'h000}), .done(done), .rd_data(rd_data));

typedef enum {IDLE, FIRST, SECOND, WAIT} FSM_STATES;
FSM_STATES state, next_state;

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		cnv_cmplt <= 1'b0;
	else if(strt_cnv)
		cnv_cmplt <= 1'b0;
	else if(fsm_complete)
		cnv_cmplt <= 1'b1;
	else 
		cnv_cmplt <= cnv_cmplt;

end

always_comb begin
	wrt = 0;
	fsm_complete = 0;
	next_state = IDLE;
	case(state)
		IDLE: begin
			if(strt_cnv) begin
				wrt = 1'b1;
				next_state = FIRST;	
			end
			else
				next_state = IDLE;
		end
	
		FIRST:	begin
			if(done) begin
				next_state = WAIT;
			end
			else
				next_state = FIRST;
		end

		SECOND: begin
			if(done) begin
				fsm_complete = 1'b1;
				next_state = IDLE;
			end
			else
				next_state = SECOND;
		end

		WAIT: begin
			wrt = 1'b1;
			next_state = SECOND;
		end
	endcase
		
end

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

endmodule