module ESC_interface(clk, rst_n, speed, off, pwm);

parameter PERIOD_WIDTH = 18;

input clk, rst_n;
input [10:0] speed;
input [9:0] off;

output reg pwm; 
reg [PERIOD_WIDTH-1:0] twenty_bit;

wire [11:0] compensated_speed; 
wire [15:0] promoted;
wire [16:0] setting; 
wire comp, rst, set;

assign compensated_speed = speed + off;

assign promoted = compensated_speed*16;

assign setting = promoted + 16'd50000;

// compensator greater than or equal, output either 0 or 1
assign rst = (twenty_bit[16:0] >= setting) ? 1'b1 : 1'b0;

// & (all bits set)
assign set = &twenty_bit;

// counter
always @(posedge clk, negedge rst_n)
  begin
  if(!rst_n)
    twenty_bit <= 20'b0;
  else
    twenty_bit <= (twenty_bit + 1'b1);
  end

// flop with reset, set and pwm
always @(posedge clk, negedge rst_n)
  begin
  if(!rst_n)
    pwm <= 1'b0;
  else
    if(set) 		// if rst, get 1
      pwm <= 1'b1;
    else if(rst) 	// if set, get 0
      pwm <= 1'b0;
    else 		// if neither, get pwem
      pwm <= pwm;
  end

endmodule
