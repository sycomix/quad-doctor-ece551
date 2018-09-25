module rst_synch(RST_n, clk, rst_n);

input RST_n, clk;
output logic rst_n;

logic q1, q2;

always_ff @(negedge clk, negedge RST_n) begin
	if(!RST_n)
	q1 <= 1'b0;
	else
	q1 <= 1'b1;
end

always_ff @(negedge clk, negedge RST_n) begin
	if(!RST_n)
	q2 <= 1'b0;
	else
	q2 <= q1;
end
	
assign rst_n = q2;

endmodule
