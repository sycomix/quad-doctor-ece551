module UART(clk,rst_n,trmt,tx_data,rdy,rx_data,RX,clr_rdy,TX,tx_done);
  input clk, rst_n, trmt, RX, clr_rdy;
  input [7:0]tx_data; //byte that will be transmitted
  output TX; //bit of tx_shift_reg the will be shifted out
  output tx_done;  //signal done
  output[7:0]rx_data;
  output rdy;

UART_tx iDUT(.clk(clk),.rst_n(rst_n),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done),.TX(TX));

UART_rcv iDUT2(.clk(clk),.rst_n(rst_n),.RX(RX),.clr_rdy(clr_rdy),.rx_data(rx_data),.rdy(rdy));

endmodule

