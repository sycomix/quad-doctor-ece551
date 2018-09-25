module PreFF(d, q, rst_n, clk);

input d, rst_n, clk;
output logic q;


always_ff@(negedge rst_n, posedge clk) begin

	if(!rst_n)
		q <= 1'b1;

	else
		q <= d;

end


endmodule


module PB_release(PB, clk, rst_n, released);

input PB, clk, rst_n;
output logic released;

logic wire1;
logic wire2;
logic wire3;

PreFF first(.d(PB), .clk(clk), .rst_n(rst_n), .q(wire1));
PreFF second(.d(wire1), .clk(clk), .rst_n(rst_n), .q(wire2));
PreFF third(.d(wire2), .clk(clk), .rst_n(rst_n), .q(wire3));

assign released = wire2 & ~wire3;


endmodule



