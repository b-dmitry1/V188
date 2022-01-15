module USBtx(
	input wire clk,
	input wire clk60,
	
	input wire fullspeed,
	
	input wire [7:0] din,
	input wire wrin,
	output reg wrout,
	
	input wire force0,
	input wire send_eop_in,
	output reg send_eop_out,
	
	output reg transmitting,

	output reg [2:0] numbits,
	
	output reg dm,
	output reg dp
);

initial
begin
    dm = 1'b0;
    dp = 1'b0;
    wrout = 1'b0;
    numbits = 3'd0;
    div <= 6'd0;
    prescaler <= 6'd0;
    send_eop_out <= 1'b0;
	 transmitting = 1'b0;
	bitclk <= 1'b0;
end

reg [5:0] div;
reg [5:0] prescaler;

reg bitclk;

reg wr;
reg [7:0] dinbuf;

reg [6:0] d;
reg curbit;
reg [2:0] ones;

reg [1:0] eop;

always @(posedge clk)
begin
	dinbuf <= din;
end

always @(posedge clk60)
begin
	prescaler <= fullspeed ? 6'd4 : 6'd39;
	div <= div == prescaler ? 6'd0 : div + 1'd1;
	
	bitclk <= div == prescaler;
	
	// transmitting <= force0 || (wr) || (|numbits) || (|eop);
end

always @(posedge bitclk)
begin
	// dinbuf <= din;
	wr <= wrin ^ wrout;
	
	if (force0 || (^eop))
	begin
		dm <= 1'b0;
		dp <= 1'b0;
	end
	else if (curbit)
	begin
		dm <= fullspeed;
		dp <= ~fullspeed;
	end
	else
	begin
		dm <= ~fullspeed;
		dp <= fullspeed;
	end
	
	if (numbits == 3'd0)
	begin
		if (send_eop_in ^ send_eop_out)
		begin
			ones <= 3'd0;
			eop <= 2'b11;
			transmitting <= 1'b1;
			curbit <= fullspeed;
			send_eop_out <= send_eop_in;
		end
		else if (wrin ^ wrout)
		begin
			d <= dinbuf[7:1];
			if (dinbuf[0] == 1'b0)
				curbit <= ~curbit;
			else
				ones <= ones + 1'd1;
			numbits <= 3'd7;
			transmitting <= 1'b1;
			wrout <= wrin;
		end
		else
		begin
			ones <= 3'd0;
			curbit <= fullspeed;
			if (|eop)
			    eop <= eop - 1'd1;
			else
				transmitting <= force0;
		end
	end
	else
	begin
		/*
		if (ones == 3'd6)
		begin
			curbit <= ~curbit;
			ones <= 3'd0;
		end
		else
		begin
		*/
			numbits <= numbits - 1'd1;
			if ((numbits == 3'd1) && (wrin == wrout))
    			eop <= 2'b11;
			d[5:0] <= d[6:1];
			if (d[0] == 1'b0)
			begin
				curbit <= ~curbit;
				ones <= 3'd0;
			end
			else
				ones <= ones + 1'd1;
//		end
	end
end

endmodule
