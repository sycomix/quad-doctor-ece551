module inert_intf(clk,rst_n,MISO,INT,strt_cal,SS_n,SCLK,MOSI,vld,cal_done,ptch,roll,yaw);

input clk, rst_n;
input MISO, INT, strt_cal;

output SS_n, SCLK, MOSI, cal_done;
output reg vld;
output[15:0] ptch, roll, yaw;

logic[15:0] rd_data;
logic[15:0] cmd;
logic[15:0] timer;
logic wrt, done, INT_ff1, INT_ff2;
logic[7:0] pitchL, pitchH, rollL, rollH, yawL, yawH, AXL, AXH, AYL, AYH;
logic[15:0] ptch_rt, roll_rt, yaw_rt, ax, ay;
localparam full_timer = 16'hFFFF;

SPI_mstr16 iDUT(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),.wrt(wrt),.cmd(cmd),.done(done),.rd_data(rd_data));
inertial_integrator #(3) iDUT1(.clk(clk),.rst_n(rst_n),.strt_cal(strt_cal),.cal_done(cal_done),.vld(vld),.ptch_rt(ptch_rt),.roll_rt(roll_rt),.yaw_rt(yaw_rt),.ax(ax),.ay(ay),.ptch(ptch),.roll(roll),.yaw(yaw));

assign ptch_rt = {pitchH, pitchL};
assign roll_rt = {rollH, rollL};
assign yaw_rt = {yawH, yawL};
assign ax = {AXH, AXL};
assign ay = {AYH, AYL};

typedef enum {INIT1, INIT2, INIT3, INIT4, INITIAL, PITCHL, PITCHH, ROLLL, ROLLH, YAWL, YAWH, AXLOW, AXHIGH, AYLOW, AYHIGH, VALID} state_t;
state_t state, next_state; 

//////////////////////////////////////
///TIMER//////////////////////////////
//////////////////////////////////////
always@(posedge clk, negedge rst_n)begin
  if(!rst_n)
    timer <= 16'h0000;
  else if (timer == full_timer)
    timer <= 16'h0000;
  else
    timer <= timer + 1;
end

always@(posedge clk, negedge rst_n)begin
  if(!rst_n)
    state <= INIT1;
  else
    state <= next_state;
end

always@(posedge clk, negedge rst_n)begin
  if(!rst_n)
    INT_ff1 <= 1'b0;
  else
    INT_ff1 <= INT;
end

always@(posedge clk, negedge rst_n)begin
  if(!rst_n)
    INT_ff2 <= 1'b0;
  else
    INT_ff2 <= INT_ff1;
end

typedef enum {init,select_pl,select_ph,select_rl,select_rh,select_yl,select_yh,select_axl,select_axh,select_ayl,select_ayh}select_read;
select_read select;

always@(posedge clk)begin
  if(select == select_pl)
    pitchL <= rd_data[7:0];
  else if(select == select_ph)
    pitchH <= rd_data[7:0];
  else if(select == select_rl)
    rollL <= rd_data[7:0];
  else if(select == select_rh)
    rollH <= rd_data[7:0];
  else if(select == select_yl)
    yawL <= rd_data[7:0];
  else if(select == select_yh)
    yawH <= rd_data[7:0];
  else if(select == select_axl)
    AXL <= rd_data[7:0];
  else if(select == select_axh)
    AXH <= rd_data[7:0];
  else if(select == select_ayl)
    AYL <= rd_data[7:0];
  else if(select == select_ayh)
    AYH <= rd_data[7:0];
end

always_comb begin
  wrt = 0;
  cmd = 16'h0000;
  vld = 0;
  select = init;
  next_state = INIT1;
  case(state)
    INIT1: begin 
      cmd = 16'h0D02;
      if(timer == full_timer)begin
	wrt = 1;
	next_state = INIT2;
      end else
	next_state = INIT1;
    end
    INIT2: begin
      cmd = 16'h1062;
      if(done)begin
	wrt = 1;
	next_state = INIT3;
      end else
	next_state = INIT2;
    end
    INIT3: begin
      cmd = 16'h1162;
      if(done)begin
	wrt = 1;
	next_state = INIT4;
      end else
	next_state = INIT3;
    end
    INIT4: begin
      cmd = 16'h1460;
      if(done)begin
	wrt = 1;
	next_state = INITIAL;
      end else
	next_state = INIT4;
    end
    INITIAL: begin
      if(INT_ff2)begin
        next_state = PITCHL;
        cmd = 16'hA2xx;
        wrt = 1;
    end else
      next_state = INITIAL;
    end
    PITCHL: begin
      //cmd = 16'hA2xx;
      //wrt = 1;
      select = select_pl;
      if(done)begin
	next_state = PITCHH;
        cmd = 16'hA3xx;
        wrt = 1;
      end else 
	next_state = PITCHL;
    end
    PITCHH: begin
      //cmd = 16'hA3xx;
      //wrt = 1;
      select = select_ph;
      if(done)begin
	next_state = ROLLL;
        cmd = 16'hA4xx;
        wrt = 1;
      end else 
	next_state = PITCHH;
    end
    ROLLL: begin
      //cmd = 16'hA4xx;
      //wrt = 1;
      select = select_rl;
      if(done)begin
	next_state = ROLLH;
        cmd = 16'hA5xx;
        wrt = 1;
      end else
	next_state = ROLLL;
    end
    ROLLH: begin
      //cmd = 16'hA5xx;
      //wrt = 1;
      select = select_rh;
      if(done)begin
	next_state = YAWL;
        cmd = 16'hA6xx;
        wrt = 1;
      end else
	next_state = ROLLH;
    end
    YAWL: begin
      //cmd = 16'hA6xx;
      //wrt = 1;
      select = select_yl;
      if(done)begin
	next_state = YAWH;
        cmd = 16'hA7xx;
        wrt = 1;
      end else
	next_state = YAWL;
    end
    YAWH: begin
      //cmd = 16'hA7xx;
      //wrt = 1;
      select = select_yh;
      if(done)begin
	next_state = AXLOW;
        cmd = 16'hA8xx;
        wrt = 1;
      end else
	next_state = YAWH;
    end
    AXLOW: begin
      //cmd = 16'hA8xx;
      //wrt = 1;
      select = select_axl;
      if(done)begin
	next_state = AXHIGH;
        cmd = 16'hA9xx;
        wrt = 1;
      end else
	next_state = AXLOW;
    end
    AXHIGH: begin
      //cmd = 16'hA9xx;
      //wrt = 1;
      select = select_axh;
      if(done)begin
	next_state = AYLOW;
        cmd = 16'hAAxx;
        wrt = 1;
      end else
	next_state = AXHIGH;
    end
    AYLOW: begin
      //cmd = 16'hAAxx;
      //wrt = 1;
      select = select_ayl;
      if(done)begin
	next_state = AYHIGH;
        cmd = 16'hABxx;
        wrt = 1;
      end else
	next_state = AYLOW;
    end
    AYHIGH: begin
      //cmd = 16'hABxx;
      //wrt = 1;
      select = select_ayh;
      if(done) begin
	next_state = VALID;
      end else
	next_state = AYHIGH;
    end
    VALID: begin
      vld = 1;
      next_state = INITIAL;
    end
  endcase
end
endmodule