//SAMUel Rinartz
module SPI_mstr16(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, cmd, done, rd_data);

//inputs and outputs 
input clk, rst_n, wrt;
output logic SS_n, SCLK;
output logic MOSI; 
input MISO;
input [15:0] cmd;
output logic done;
output logic [15:0] rd_data;

//internal
logic [4:0] sclk_div;
logic [3:0] bit_counter;
logic set_done;
logic clr_done;
logic set_SS_n;
logic reset_SS_n;

//state machine inputs/outputs
logic smpl;
logic MISO_smpl;
logic shft = 0;
logic rst_cnt;
logic clr_SSn;
logic set_SSn;

assign SCLK = sclk_div[4];
assign MOSI = rd_data[15];

//SCLK counter
always@(negedge rst_n, posedge clk)begin
	if(!rst_n)begin
		sclk_div <= 5'b10111;//TODO double check
	end
	else if(rst_cnt)begin
		sclk_div <= 5'b10111;
	end
	else begin
		sclk_div <= sclk_div + 1;
	end
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		MISO_smpl <= 1'b0;
	else if(smpl)
		MISO_smpl <= MISO;
	else
		MISO_smpl <= MISO_smpl;
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		rd_data <= 16'h0000;//TODO what is reset condition
	else if(wrt)begin
		rd_data <= cmd;
	end
	else if(shft)
		rd_data <= {rd_data[14:0], MISO_smpl};
	else
		rd_data <= rd_data;
end

//bit counter
always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		bit_counter <= 0;
	else if(rst_cnt)
		bit_counter <= 0;
	else if(shft)
		bit_counter <= bit_counter + 1;	
	else
		bit_counter <= bit_counter;
end

//state machine stuff
typedef enum {IDLE, FRONT_PORCH, BITS, BACK_PORCH} FSM_STATES;
FSM_STATES state, next_state;

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

always_comb begin
	rst_cnt = 0;//TODO when do we use this
	shft = 0;
	clr_SSn = 0;
	set_SSn = 0;
	set_done = 1'b0;
	clr_done = 1'b0;
	smpl = 0;
	next_state = IDLE;

	case(state)
		IDLE:begin
			if(wrt)begin
				next_state = FRONT_PORCH;
				clr_done = 1;
				rst_cnt = 1;//TODO should rst_cnt still be asserted on transition?
				clr_SSn = 1'b1;
			end
			else begin
				set_SSn = 1'b1;
				next_state = IDLE;
				rst_cnt = 1;
			end
		end
		FRONT_PORCH:begin
			if(sclk_div == 5'b01111)begin
				next_state = BITS;
				smpl = 1;
			end
			else begin
				next_state = FRONT_PORCH;
			end
		end
		BITS:begin
			if(bit_counter == 4'b1111 && sclk_div == 5'b11111) begin
				next_state = BACK_PORCH;
				rst_cnt = 1;
				shft = 1; //shift one last time
			end
			else if(sclk_div == 5'b11111)begin
				shft = 1'b1;
				next_state = BITS;
			end 
			else if(sclk_div == 5'b01111)begin
				smpl = 1;
				next_state = BITS;
			end
			else begin
				next_state = BITS;
			end
		end
		BACK_PORCH:begin
			//shft = 1; //shift one last time
			next_state = IDLE;
			set_SSn = 1;
			set_done = 1;
			rst_cnt = 1;
		end
	endcase

end

//set clr FF for done
always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		done <= 1'b0;
	else if(set_done)
		done <= 1'b1;
	else if(clr_done)
		done <= 1'b0;
	else 
		done <= done;
end

always@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		SS_n <= 1'b1;
	else if(set_SSn)
		SS_n <= 1'b1;
	else if(clr_SSn)
		SS_n <= 1'b0;
	else 
		SS_n <= SS_n;
end

endmodule
